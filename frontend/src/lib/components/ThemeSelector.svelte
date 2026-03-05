<script lang="ts">
  import { m } from '$lib/i18n/messages'

  const options = [
    { value: 'light', label: m['components.theme.options.light'](), icon: 'i-bi-sun' },
    { value: 'dark', label: m['components.theme.options.dark'](), icon: 'i-bi-moon-stars' },
    {
      value: 'system',
      label: m['components.theme.options.system'](),
      subLabel: m['components.theme.options.systemSub'](),
      icon: 'i-bi-display'
    }
  ]
</script>

<button
  aria-controls="footer-display"
  data-fr-opened="false"
  class="fr-icon-theme-fill fr-btn--icon-left fr-footer__bottom-link"
>
  {m['components.theme.title']()}
</button>

<dialog id="footer-display" aria-labelledby="footer-display-title" class="fr-modal">
  <div class="fr-container fr-container--fluid fr-container-md">
    <div class="fr-grid-row fr-grid-row--center">
      <div class="fr-col-12 fr-col-md-6 fr-col-lg-4">
        <div class="fr-modal__body rounded-md pb-0!">
          <div class="fr-modal__header">
            <button
              aria-controls="footer-display"
              title={m['closeModal']()}
              type="button"
              id="button-14"
              class="fr-btn--close fr-btn rounded-md"
            >
              {m['words.close']()}
            </button>
          </div>
          <div class="fr-modal__content mb-0!">
            <h2 id="footer-display-title" class="fr-modal__title">
              {m['components.theme.title']()}
            </h2>
            <div id="fr-display" class="fr-display">
              <fieldset
                class="fr-fieldset"
                id="display-fieldset"
                aria-labelledby="display-fieldset-legend display-fieldset-messages"
              >
                <legend
                  class="fr-fieldset__legend--regular fr-fieldset__legend"
                  id="display-fieldset-legend"
                >
                  {m['components.theme.legend']()}
                </legend>

                {#each options as option (option.value)}
                  <div class="fr-fieldset__element">
                    <div class="fr-radio-group fr-radio-rich">
                      <input
                        value={option.value}
                        type="radio"
                        id="fr-radios-theme-{option.value}"
                        name="fr-radios-theme"
                      />
                      <label class="fr-label" for="fr-radios-theme-{option.value}">
                        {option.label}
                        {#if option.subLabel}
                          <span class="fr-hint-text">{option.subLabel}</span>
                        {/if}
                      </label>
                      <div class="fr-radio-rich__pictogram flex items-center justify-center">
                        <span class="{option.icon} text-2xl" aria-hidden="true"></span>
                      </div>
                    </div>
                  </div>
                {/each}

                <div
                  class="fr-messages-group"
                  id="display-fieldset-messages"
                  aria-live="polite"
                ></div>
              </fieldset>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</dialog>

<style>
  .fr-radio-rich {
    border-radius: 0.375rem;
    overflow: hidden;
    box-shadow: inset 0 0 0 1px var(--border-default-grey);
    transition: box-shadow 0.3s ease;
  }

  .fr-radio-rich:has(input:checked) {
    box-shadow: inset 0 0 0 2px var(--blue-france-main-525);
  }

  .fr-radio-rich :global(input[type="radio"] + label),
  .fr-radio-rich :global(.fr-radio-rich__pictogram) {
    background-image: none !important;
  }

  .fr-radio-rich :global(input[type="radio"]:checked + label) {
    color: var(--blue-france-main-525);
    font-weight: 700;
  }
</style>
