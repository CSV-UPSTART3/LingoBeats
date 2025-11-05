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
        const atBottom = results.scrollHeight - results.scrollTop === results.clientHeight;

        if (!results.contains(e.target)) {
          e.preventDefault();
          results.scrollTop += e.deltaY;
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
      searchInput.placeholder = placeholders[cat] || 'Enter keywords to find songs';

      requestAnimationFrame(() => {
        slider.style.left = link.offsetLeft + 'px';
        slider.style.width = link.offsetWidth + 'px';
      });
    };

    // --- URL, session, default, home logic ---
    const urlParams = new URLSearchParams(window.location.search);
    const urlCategory = urlParams.get('category');
    const serverDefault = 'song_name';

    // Determine which category to use
    let categoryToUse = sessionStorage.getItem('lastCategory');

    if (urlCategory && ['song_name', 'singer'].includes(urlCategory)) {
      // Priority 1: Use URL category if specified
      categoryToUse = urlCategory;
      sessionStorage.setItem('lastCategory', categoryToUse);
      console.log('[Use URL category]', categoryToUse);
    } else if (categoryToUse && ['song_name', 'singer'].includes(categoryToUse)) {
      // Priority 2: Use session category if available
      console.log('[Use session category]', categoryToUse);
    } else {
      // Priority 3: Default to song_name
      categoryToUse = 'song_name';
      sessionStorage.setItem('lastCategory', categoryToUse);
      console.log('[Init default]', categoryToUse);
    }

    // Initialize UI state
    const initialLink = Array.from(links).find(a => (a.dataset.category || '') === categoryToUse) || links[0];
    if (initialLink) setActive(initialLink);

    links.forEach(link => {
      link.addEventListener('click', e => {
        e.preventDefault();
        setActive(link);
        sessionStorage.setItem('lastCategory', link.dataset.category || serverDefault);
      });
    });

    if (form) {
      form.addEventListener('submit', () => {
        const active = getActiveLink();
        const cat = (active?.dataset.category) || categoryInput.value || serverDefault;
        categoryInput.value = cat;
        sessionStorage.setItem('lastCategory', cat);
        sessionStorage.setItem('lastSearchQuery', searchInput.value.trim());
      });
    }

    // --- Enable/disable submit button dynamically ---
    const toggleSubmit = () => {
      if (submitBtn) submitBtn.disabled = !searchInput.value.trim();
    };
    searchInput.addEventListener('input', toggleSubmit);
    toggleSubmit();

    // --- Relocate slider on resize/load ---
    const relocate = () => {
      const a = getActiveLink();
      if (!a) return;
      requestAnimationFrame(() => {
        slider.style.left = a.offsetLeft + 'px';
        slider.style.width = a.offsetWidth + 'px';
      });
    };
    window.addEventListener('resize', relocate);
    window.addEventListener('load', relocate);

    // --- Song Modal Logic ---
    const songModal = document.getElementById('songModal');
    let scrollPosition = 0;

    // prevent scroll function
    function preventScroll(e) {
      e.preventDefault();
      e.stopPropagation();
      return false;
    }
    
    if (songModal) {
      songModal.addEventListener('show.bs.modal', function () {
        scrollPosition = window.pageYOffset;
        
        // lock body
        document.body.style.overflow = 'hidden';
        document.body.style.position = 'fixed';
        document.body.style.top = `-${scrollPosition}px`;
        document.body.style.width = '100%';
        
        // prevent all scrolling
        document.addEventListener('wheel', preventScroll, { passive: false });
        document.addEventListener('touchmove', preventScroll, { passive: false });
        document.addEventListener('scroll', preventScroll, { passive: false });
      });

      songModal.addEventListener('hidden.bs.modal', function () {
        // remove scroll prevention
        document.removeEventListener('wheel', preventScroll);
        document.removeEventListener('touchmove', preventScroll);
        document.removeEventListener('scroll', preventScroll);

        // restore
        document.body.style.overflow = '';
        document.body.style.position = '';
        document.body.style.top = '';
        document.body.style.width = '';
        window.scrollTo(0, scrollPosition);
      });

      // allow scrolling within modal lyrics area
      const modalLyrics = document.getElementById('modalLyrics');
      if (modalLyrics) {
        modalLyrics.addEventListener('wheel', function(e) {
          e.stopPropagation();
        });
        modalLyrics.addEventListener('touchmove', function(e) {
          e.stopPropagation();
        });
      }
    }

    document.addEventListener('click', (e) => {
      const card = e.target.closest('.song-card');
      if (!card) return;
      if (e.target.closest('.singer-link') || e.target.closest('.play-overlay')) return;

      const singerLinks = card.querySelectorAll('.singer-link');
      const singers = Array.from(singerLinks).map(link => ({
        name: link.textContent.trim(),
        external_url: link.href
      }));

      const songData = {
        id:    card.dataset.id || '',
        name:  card.dataset.songName || '',
        album: card.dataset.albumName || '',
        cover: card.dataset.cover || '/assets/img/placeholder-album.png',
        url:   card.dataset.url || '#',
        singers
      };

      updateSongModal(songData);

      const modalEl = document.getElementById('songModal');
      const bsModal = bootstrap.Modal.getOrCreateInstance(modalEl);
      bsModal.show();
    }, true);

    function updateSongModal(data) {
      const modalEl = document.getElementById('songModal');
      if (!modalEl) return;

      modalEl.querySelector('#modalSongTitle').textContent = data.name;
      modalEl.querySelector('#modalAlbum').textContent = data.album;
      modalEl.querySelector('#modalCover').src = data.cover;
      modalEl.querySelector('#modalCover').alt = data.album || 'Cover';
      modalEl.querySelector('#modalPlayOverlay').href = data.url;

      const singersEl = modalEl.querySelector('#modalSingers');
      if (data.singers?.length) {
        singersEl.innerHTML = data.singers
          .map(s => `<a class="singer-link" href="${s.external_url}" target="_blank" rel="noopener">${s.name}</a>`)
          .join(', ');
      } else {
        singersEl.textContent = 'Unknown';
      }

      const lyricsEl = document.getElementById('modalLyrics');
      lyricsEl.style.whiteSpace = 'pre-wrap';
      lyricsEl.scrollTop = 0;
      lyricsEl.innerHTML = `
        <div class="text-center text-muted py-3">
          <i class="fas fa-spinner fa-spin fa-2x mb-1 d-block"></i>
          <p>Loading lyrics...</p>
        </div>`;

      const primaryArtist = data.singers?.[0]?.name || '';
      loadLyrics(data.id, data.name, primaryArtist);
    }

    async function loadLyrics(songId, songName, singerName) {
      const lyricsEl = document.getElementById('modalLyrics');
      lyricsEl.classList.add('loading');
      lyricsEl.innerHTML = `
        <div class="text-center text-muted py-3">
          <i class="fas fa-spinner fa-spin fa-2x mb-1 d-block"></i>
          <p>Loading lyrics...</p>
        </div>`;

      try {
        const params = new URLSearchParams();
        if (songId) params.set('id', songId);
        if (songName) params.set('name', songName);
        if (singerName) params.set('singer', singerName);

        const res  = await fetch(`/lyrics/song?${params.toString()}`, { cache: 'no-store' });
        const html = await res.text();
        if (!res.ok) throw new Error(`HTTP ${res.status}`);

        lyricsEl.classList.remove('loading');
        lyricsEl.innerHTML = html;
      } catch (e) {
        lyricsEl.classList.remove('loading');
        lyricsEl.innerHTML = `
          <div class="text-center text-danger py-5">
            <i class="fas fa-exclamation-triangle fa-2x mb-1 d-block"></i>
            <p>Failed to load lyrics: ${e.message}</p>
          </div>`;
      }
    }
  });
})();