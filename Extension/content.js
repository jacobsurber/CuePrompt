// CuePrompt Companion — Content script for Google Slides
// Reads speaker notes from the DOM and watches for slide transitions.

(function () {
  "use strict";

  let currentSlideIndex = -1;
  let totalSlides = 0;
  let observer = null;

  // Detect if we're in presentation mode or edit mode
  function isPresenting() {
    return (
      document.querySelector(".punch-viewer-container") !== null ||
      window.location.hash.includes("slide=") ||
      document.fullscreenElement !== null
    );
  }

  function isEditMode() {
    return document.querySelector(".punch-filmstrip") !== null;
  }

  // Get the current slide index from the filmstrip or slide counter
  function detectCurrentSlide() {
    // Edit mode: check filmstrip selection
    const filmstrip = document.querySelector(".punch-filmstrip");
    if (filmstrip) {
      const selected = filmstrip.querySelector(
        '[aria-selected="true"], .punch-filmstrip-thumbnail-selected'
      );
      if (selected) {
        const thumbnails = filmstrip.querySelectorAll(
          ".punch-filmstrip-thumbnail"
        );
        for (let i = 0; i < thumbnails.length; i++) {
          if (
            thumbnails[i] === selected ||
            thumbnails[i].contains(selected)
          ) {
            return i;
          }
        }
      }
    }

    // Present mode: check slide counter "3 / 12"
    const counter = document.querySelector(
      '.punch-viewer-speakernotes-page-num, [class*="slide-counter"]'
    );
    if (counter) {
      const match = counter.textContent.match(/(\d+)\s*\/\s*(\d+)/);
      if (match) {
        return parseInt(match[1], 10) - 1; // 0-indexed
      }
    }

    return currentSlideIndex;
  }

  // Get total slide count
  function detectTotalSlides() {
    const filmstrip = document.querySelector(".punch-filmstrip");
    if (filmstrip) {
      return filmstrip.querySelectorAll(".punch-filmstrip-thumbnail").length;
    }

    const counter = document.querySelector(
      '.punch-viewer-speakernotes-page-num, [class*="slide-counter"]'
    );
    if (counter) {
      const match = counter.textContent.match(/(\d+)\s*\/\s*(\d+)/);
      if (match) {
        return parseInt(match[2], 10);
      }
    }

    return totalSlides;
  }

  // Read speaker notes for a given slide (or current if in present mode)
  function readSpeakerNotes() {
    // Present mode notes panel
    const notesPanel = document.querySelector(
      ".punch-viewer-speakernotes-text"
    );
    if (notesPanel) {
      return notesPanel.textContent.trim();
    }

    // Edit mode notes panel
    const editNotes = document.querySelector(
      '.punch-viewer-speakernotes-text, [class*="speakernotes"] [contenteditable], .goog-inline-block.punch-viewer-speakernotes-text'
    );
    if (editNotes) {
      return editNotes.textContent.trim();
    }

    return "";
  }

  // Read the slide title (from the current slide's content)
  function readSlideTitle() {
    const titleEl = document.querySelector(
      '.punch-viewer-content [class*="title"], .punch-viewer-svgpage-svgcontainer text:first-child'
    );
    return titleEl ? titleEl.textContent.trim() : "";
  }

  // Perform a full sync: read all slides' notes
  function performFullSync() {
    const slides = [];
    const filmstrip = document.querySelector(".punch-filmstrip");

    if (filmstrip) {
      const thumbnails = filmstrip.querySelectorAll(
        ".punch-filmstrip-thumbnail"
      );
      totalSlides = thumbnails.length;

      // We can only read notes for the currently selected slide from the DOM.
      // Send what we have and update as slides change.
      for (let i = 0; i < thumbnails.length; i++) {
        slides.push({
          slideIndex: i,
          speakerNotes: i === currentSlideIndex ? readSpeakerNotes() : "",
          slideTitle: "",
        });
      }
    } else {
      // Present mode: we can only see the current slide
      totalSlides = detectTotalSlides();
      for (let i = 0; i < totalSlides; i++) {
        slides.push({
          slideIndex: i,
          speakerNotes: i === currentSlideIndex ? readSpeakerNotes() : "",
          slideTitle: i === currentSlideIndex ? readSlideTitle() : "",
        });
      }
    }

    chrome.runtime.sendMessage({
      type: "fullSync",
      slides: slides,
    });
  }

  // Send a slide update when the current slide changes
  function sendSlideUpdate(slideIndex) {
    chrome.runtime.sendMessage({
      type: "slideUpdate",
      slideIndex: slideIndex,
      totalSlides: totalSlides,
      speakerNotes: readSpeakerNotes(),
      slideTitle: readSlideTitle(),
    });
  }

  // Poll for slide changes (DOM mutations don't always catch everything)
  function pollForChanges() {
    const newIndex = detectCurrentSlide();
    const newTotal = detectTotalSlides();

    if (newTotal !== totalSlides) {
      totalSlides = newTotal;
    }

    if (newIndex !== currentSlideIndex && newIndex >= 0) {
      currentSlideIndex = newIndex;
      sendSlideUpdate(currentSlideIndex);
    }
  }

  // Set up a MutationObserver for DOM changes
  function setupObserver() {
    if (observer) observer.disconnect();

    observer = new MutationObserver(() => {
      pollForChanges();
    });

    // Watch the main content area for changes
    const target =
      document.querySelector(".punch-viewer-container") ||
      document.querySelector(".punch-filmstrip") ||
      document.body;

    observer.observe(target, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ["aria-selected", "class"],
    });
  }

  // Initialize
  function init() {
    if (!isEditMode() && !isPresenting()) {
      // Not on a slides page, retry after a delay
      setTimeout(init, 2000);
      return;
    }

    currentSlideIndex = detectCurrentSlide();
    totalSlides = detectTotalSlides();

    // Initial full sync
    performFullSync();

    // Watch for changes
    setupObserver();

    // Also poll every 500ms as a fallback
    setInterval(pollForChanges, 500);
  }

  // Wait for the page to be ready
  if (document.readyState === "complete") {
    setTimeout(init, 1000);
  } else {
    window.addEventListener("load", () => setTimeout(init, 1000));
  }
})();
