(() => {
  document.addEventListener('DOMContentLoaded', () => {
    // --- Tooltip initialization ---
    const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.forEach(el => new bootstrap.Tooltip(el));

    // --- Show no-result message if applicable ---
    const searchInput = document.getElementById('spotify_query_input');
    const query = sessionStorage.getItem('lastSearchQuery');
    const msg = document.getElementById('noResultMsg');

    if (searchInput && query) searchInput.value = query;
    if (query && msg) msg.textContent = `Cannot find result with "${query}"`;

    // --- Scroll behavior for .results-container ---
    document.addEventListener(
      'wheel',
      e => {
        const results = document.querySelector('.results-container');
        if (!results) return;

        const atTop = results.scrollTop === 0;
        const atBottom =
          results.scrollHeight - results.scrollTop === results.clientHeight;

        // scroll when the target is not results-container
        if (!results.contains(e.target)) {
          e.preventDefault();
          results.scrollTop += e.deltaY; // let the results scroll
        } else if ((atTop && e.deltaY < 0) || (atBottom && e.deltaY > 0)) {
          e.preventDefault();
        }
      },
      { passive: false }
    );

    // --- Pill Switch + Search logic ---
    const switcher = document.querySelector('.pill-switch');
    const slider = switcher?.querySelector('.slider');
    const links = switcher ? switcher.querySelectorAll('.nav-link') : [];
    const submitBtn = document.getElementById('submitBtn');
    const categoryInput = document.getElementById('category');
    const form = document.getElementById('spotify-form');

    if (!switcher || !slider || !searchInput || !categoryInput) return;

    const placeholders = {
      song_name: 'e.g. Shape of You',
      singer: 'e.g. Taylor Swift'
    };

    const getActiveLink = () => switcher.querySelector('.nav-link.active');

    const setActive = link => {
      links.forEach(a => {
        a.classList.remove('active', 'text-white');
        a.setAttribute('aria-selected', 'false');
      });
      link.classList.add('active', 'text-white');
      link.setAttribute('aria-selected', 'true');

      const cat = link.dataset.category || 'song_name';
      categoryInput.value = cat;
      searchInput.placeholder = placeholders[cat] || 'Search...';

      requestAnimationFrame(() => {
        slider.style.left = link.offsetLeft + 'px';
        slider.style.width = link.offsetWidth + 'px';
      });
    };

    // Tab switching
    links.forEach(link => {
      link.addEventListener('click', e => {
        e.preventDefault();
        setActive(link);
      });
    });

    // Save search info
    if (form) {
      form.addEventListener('submit', () => {
        sessionStorage.setItem('lastSearchQuery', searchInput.value.trim());
        sessionStorage.setItem('lastCategory', categoryInput.value);
      });
    }

    // Initial state
    const isHome = window.location.pathname === '/';
    let lastCategory = 'song_name';
    if (!isHome) {
      lastCategory = sessionStorage.getItem('lastCategory') || 'song_name';
    } else {
      sessionStorage.removeItem('lastCategory');
    }

    const initialLink =
      Array.from(links).find(a => (a.dataset.category || '') === lastCategory) ||
      links[0];
    if (initialLink) setActive(initialLink);

    // Enable / disable submit
    const toggleSubmit = () => {
      if (submitBtn) submitBtn.disabled = !searchInput.value.trim();
    };
    searchInput.addEventListener('input', toggleSubmit);
    toggleSubmit();

    // Relocate slider when resizing or loading
    const relocate = () => {
      const a = getActiveLink();
      if (a) setActive(a);
    };
    window.addEventListener('resize', relocate);
    window.addEventListener('load', relocate);
  });
})();
