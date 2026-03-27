<script lang="ts">
  import { Button, Link } from '$components/dsfr'
  import { m } from '$lib/i18n/messages'
  import { LanguageSelector, Menubar } from '.'

  let {
    hideNavigation = true,
    hideLanguageSelector = false,
    hideDiscussBtn = false,
    small
  }: {
    hideNavigation?: boolean
    hideLanguageSelector?: boolean
    hideDiscussBtn?: boolean
    small?: boolean
  } = $props()
</script>

<header id="main-header" class="fr-header lg:overflow-visible overflow-hidden">
  <div class="fr-header__body">
    <div class="fr-container max-w-none!">
      <div class={['fr-header__body-row flex w-full items-center px-2!', { 'lg:py-1!': small }]}>
        
        <div class="flex-1 flex justify-start min-w-0">
          <div class={['fr-header__brand fr-enlarge-link lg:rounded-full', { 'lg:-translate-x-1/8 lg:scale-75': small }]}>
            <div class="fr-header__service flex items-center before:content-none! mx-1! sm:mx-3!">
              <img 
                src="/orgs/logo_litteratia_upscaled.png"
                alt=""
                width="46"
                class="me-4 sm:block hidden h-max rounded-lg"
              />
              <div class="min-w-0">
                <p class="fr-header__service-title mb-0! leading-normal! truncate">
                  <a href="/" title={m['header.homeTitle']()}>
                    {m['header.title']()}
                  </a>
                </p>
                <p class="fr-header__service-tagline mb-0! leading-normal! text-dark-grey md:text-[14px]! text-[10px]! truncate">
                  {m['header.subtitle']()}
                </p>
              </div>
            </div>
          </div>
        </div>

        <div class="flex-none flex flex-row items-center justify-center gap-2 md:gap-6 px-2 z-10">
          <div class="text-black">
            <svg version="1.0" xmlns="http://www.w3.org/2000/svg"
              class="h-8 md:h-12 w-auto" viewBox="0 0 300 220" preserveAspectRatio="xMidYMid meet">
              <g transform="translate(0,220) scale(0.1,-0.1)" fill="currentColor" stroke="none">
                <path d="M460 1569 l0 -372 105 5 c130 7 184 30 225 95 42 66 55 132 54 278 0 151 -18 231 -67 290 -48 58 -94 75 -214 75 l-103 0 0 -371z m175 301 c49 -11 99 -62 115 -117 18 -64 24 -223 11 -298 -23 -132 -60 -173 -161 -182 l-60 -6 0 307 0 306 28 0 c15 0 45 -5 67 -10z"/>
                <path d="M1107 1875 c-26 -36 -47 -67 -47 -70 0 -3 10 -5 23 -5 21 0 71 45 131 118 l19 22 -40 0 c-37 0 -42 -4 -86 -65z"/>
                <path d="M1382 1573 l3 -368 38 -3 37 -3 0 180 0 181 90 0 90 0 0 33 0 32 -87 0 -88 0 0 125 0 125 118 0 117 0 0 33 0 32 -160 0 -160 0 2 -367z"/>
                <path d="M1782 1573 l3 -368 158 -3 157 -3 0 36 0 35 -120 0 -120 0 0 335 0 335 -40 0 -40 0 2 -367z"/>
                <path d="M2190 1570 l0 -370 175 0 175 0 0 35 0 35 -135 0 -135 0 0 145 0 145 96 0 95 0 -3 31 -3 31 -92 2 c-51 0 -93 4 -93 9 0 4 0 61 0 128 l0 120 128 -2 127 -1 3 31 3 31 -170 0 -171 0 0 -370z"/>
                <path d="M1069 1741 c-75 -23 -104 -69 -120 -191 -19 -143 14 -294 74 -333 81 -53 203 -13 243 80 20 46 18 51 -18 55 -29 3 -35 -1 -53 -37 -36 -71 -104 -81 -149 -22 -15 20 -22 47 -24 97 l-4 69 128 3 129 3 -3 60 c-1 33 -7 77 -13 98 -13 51 -63 104 -107 117 -42 11 -47 11 -83 1z m103 -91 c10 -14 21 -49 25 -78 l6 -52 -92 0 -91 0 0 34 c0 41 15 84 38 109 24 27 89 19 114 -13z"/>
                <path d="M1968 1035 c-121 -39 -229 -149 -268 -274 -93 -294 147 -582 448 -540 174 25 314 165 345 346 31 177 -69 367 -232 445 -55 26 -79 32 -156 34 -61 3 -105 -1 -137 -11z m22 -347 c3 -100 9 -161 17 -169 6 -6 25 -12 43 -13 27 -1 35 -9 59 -53 33 -61 31 -63 -62 -63 -78 0 -132 28 -161 85 -18 34 -21 61 -24 193 -2 85 -1 160 2 168 4 11 20 14 63 12 l58 -3 5 -157z"/>
                <path fill="#ffef65" d="M2228 841 c9 -1 12 -36 12 -141 0 -178 10 -199 88 -200 20 0 22 -5 22 -55 l0 -55 -50 0 c-103 0 -163 52 -180 156 -10 58 -14 287 -6 295 4 3 43 3 114 0z"/>
              </g>
            </svg>
          </div>

          <div class="text-black hidden sm:block">
            <svg version="1.0" xmlns="http://www.w3.org/2000/svg"
              class="h-8 md:h-12 w-auto" viewBox="0 0 400 231" preserveAspectRatio="xMidYMid meet">
              <g transform="translate(0,231) scale(0.1,-0.1)" fill="currentColor" stroke="none">
                <path d="M2595 2175 c-5 -2 -35 -10 -65 -19 -69 -21 -101 -36 -121 -58 -9 -10 -22 -18 -28 -18 -16 0 -52 -38 -70 -72 -8 -16 -18 -28 -23 -28 -4 0 -8 -9 -8 -19 0 -11 -4 -21 -8 -23 -4 -1 -17 -28 -27 -58 -17 -48 -21 -94 -26 -350 -6 -292 -13 -370 -30 -370 -5 0 -9 -7 -9 -15 0 -24 -80 -98 -121 -112 -19 -7 -59 -13 -87 -13 l-52 0 0 -120 0 -120 80 0 c47 0 80 4 80 10 0 6 18 10 40 10 22 0 40 5 40 10 0 6 6 10 13 10 48 0 207 127 207 165 0 8 5 15 10 15 6 0 10 9 10 20 0 11 4 20 8 20 4 0 14 28 21 63 7 34 17 72 22 85 5 13 9 151 9 307 0 183 4 285 10 285 6 0 10 11 10 23 0 34 81 117 114 117 14 0 26 5 26 10 0 6 26 10 59 10 44 0 60 4 65 16 3 9 6 63 6 120 l0 104 -72 -1 c-40 0 -77 -2 -83 -4z"/>
                <path d="M2900 1480 l0 -700 120 0 120 0 0 240 0 240 210 0 210 0 0 -240 0 -240 120 0 120 0 0 500 0 500 -120 0 -120 0 0 -135 0 -135 -210 0 -210 0 0 335 0 335 -120 0 -120 0 0 -700z"/>
                <path d="M775 1768 c-16 -6 -41 -17 -55 -25 -14 -8 -33 -17 -42 -20 -10 -3 -18 -9 -18 -14 0 -5 -4 -9 -10 -9 -5 0 -10 16 -10 35 l0 35 -130 0 -130 0 0 -495 0 -495 130 0 130 0 0 330 c0 297 2 333 17 358 24 36 39 52 52 52 6 0 11 4 11 8 0 5 19 13 43 18 84 20 163 -31 185 -118 8 -31 12 -151 12 -347 l0 -301 120 0 120 0 0 314 c0 341 2 354 57 413 46 48 169 52 213 6 49 -53 50 -61 50 -408 l0 -325 130 0 130 0 0 343 c0 314 -2 349 -20 416 -19 66 -27 80 -83 135 -67 66 -96 86 -125 86 -10 0 -23 5 -29 11 -20 20 -263 -1 -263 -22 0 -5 -9 -9 -20 -9 -11 0 -20 -4 -20 -9 0 -5 -9 -13 -20 -16 -11 -4 -32 -17 -45 -31 l-24 -24 -40 40 c-22 22 -47 40 -55 40 -9 0 -16 5 -16 10 0 6 -13 10 -30 10 -16 0 -30 5 -30 10 0 13 -145 11 -185 -2z"/>
                <path d="M1922 420 c3 -202 5 -208 77 -217 37 -5 41 -3 41 15 0 13 -11 26 -27 34 l-28 13 -3 168 -2 167 -31 0 -30 0 3 -180z"/>
                <path d="M3110 570 c0 -27 3 -30 30 -30 27 0 30 3 30 30 0 27 -3 30 -30 30 -27 0 -30 -3 -30 -30z"/>
                <path d="M2122 480 c-89 -55 -82 -218 12 -261 51 -23 71 -23 122 0 67 31 94 123 60 206 -29 69 -126 96 -194 55z m123 -50 c42 -47 23 -162 -29 -176 -60 -15 -102 36 -93 113 6 55 30 83 72 83 19 0 39 -8 50 -20z"/>
                <path d="M2486 479 c-21 -17 -26 -18 -26 -5 0 11 -9 16 -30 16 l-30 0 0 -140 0 -140 30 0 30 0 0 88 c0 100 12 127 63 140 25 6 33 14 35 35 3 23 0 27 -21 27 -13 0 -36 -9 -51 -21z"/>
                <path d="M2696 479 c-21 -17 -26 -18 -26 -5 0 11 -9 16 -30 16 l-30 0 0 -140 0 -140 30 0 30 0 0 93 c0 84 2 96 23 114 12 12 33 23 47 25 19 2 26 10 28 31 3 23 0 27 -21 27 -13 0 -36 -9 -51 -21z"/>
                <path d="M2847 484 c-17 -9 -27 -22 -25 -32 4 -17 9 -18 82 -6 42 7 66 -10 66 -48 0 -15 -8 -18 -49 -18 -33 0 -58 -7 -82 -23 -29 -20 -34 -29 -37 -70 -3 -43 -1 -48 30 -67 40 -24 69 -25 108 -5 17 9 30 11 30 5 0 -5 14 -10 30 -10 l30 0 0 104 c0 58 -4 116 -10 130 -19 51 -113 72 -173 40z m123 -173 c0 -31 -12 -44 -52 -60 -22 -8 -31 -6 -50 9 -19 15 -21 22 -12 37 14 24 52 43 87 43 23 0 27 -4 27 -29z"/>
                <path d="M3347 480 c-31 -17 -37 -17 -37 -5 0 10 -10 15 -30 15 l-30 0 0 -140 0 -140 30 0 30 0 0 99 0 99 35 22 c19 12 45 20 57 18 22 -3 23 -8 28 -118 l5 -115 30 0 30 0 0 123 c0 118 -1 125 -24 143 -30 25 -77 24 -124 -1z"/>
                <path d="M3630 487 c-65 -33 -91 -141 -52 -216 35 -69 143 -91 204 -41 22 18 22 20 5 37 -16 16 -19 16 -46 0 -16 -9 -38 -17 -49 -17 -28 0 -60 30 -68 63 l-6 27 96 0 96 0 0 31 c0 97 -96 159 -180 116z m102 -54 c34 -31 23 -43 -42 -43 -45 0 -60 3 -60 14 0 41 67 61 102 29z"/>
                <path d="M3110 350 l0 -140 30 0 30 0 0 140 0 140 -30 0 -30 0 0 -140z"/>
              </g>
            </svg>
          </div>
        </div>

        <div class="flex-1 flex justify-end items-center z-20">
          
          <div class="fr-header__navbar lg:hidden">
            <button
              class="fr-btn fr-btn--menu shadow-none! m-0!"
              data-fr-opened="false"
              aria-controls="fr-modal-menu"
              title={m['header.menu']()}
            >
              </button>
          </div>

          <div class="gap-3 p-4 lg:flex hidden items-center relative z-2">
            {#if !hideLanguageSelector}
              <LanguageSelector id="translate" />
            {/if}
            <button
              aria-controls="footer-display"
              data-fr-opened="false"
              title={m['components.theme.title']()}
              class="fr-icon-theme-fill fr-btn--icon-left fr-btn fr-btn--tertiary-no-outline rounded-lg! header-btn"
            >{m['components.theme.title']()}</button>

            {#if !hideDiscussBtn}
              <Link
                button
                href="/"
                text={m['header.startDiscussion']()}
                class="whitespace-nowrap"
              />
            {/if}
          </div>
        </div>

      </div>
    </div>
  </div>

  <dialog aria-labelledby="fr-modal-title-modal-menu" id="fr-modal-menu" class="fr-modal fr-header__menu">
    <div class="fr-container lg:p-0!">
      <Button variant="tertiary-no-outline" text={m['words.close']()} title={m['closeModal']()} aria-controls="fr-modal-menu" class="fr-btn--close" />
      <div class="fr-header__menu-links after:mt-4! lg:hidden">
        {#if !hideLanguageSelector} <LanguageSelector id="mobile-translate" /> {/if}
        <button aria-controls="footer-display" data-fr-opened="false" title={m['components.theme.title']()} class="fr-icon-theme-fill fr-btn--icon-left fr-btn fr-btn--tertiary-no-outline rounded-lg!">{m['components.theme.title']()}</button>
      </div>
      {#if !hideNavigation} <Menubar /> {/if}
      {#if !hideDiscussBtn}
        <div class="mt-6! md:mt-0 lg:hidden">
          <Link button href="/" text={m['header.startDiscussion']()} class="w-full! whitespace-nowrap" />
        </div>
      {/if}
    </div>
  </dialog>
</header>