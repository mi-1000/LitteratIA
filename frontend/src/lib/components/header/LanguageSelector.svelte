<script lang="ts">
  import { page } from '$app/state'
  import { LOCALES, type LocaleOption } from '$lib/global.svelte'
  import { m } from '$lib/i18n/messages'
  import { getLocale, setLocale } from '$lib/i18n/runtime'
  import { SvelteURL } from 'svelte/reactivity'

  let { id }: { id: string } = $props()

  const currentLocale = getLocale()
  let open = $state(false)
  let containerEl: HTMLElement

  function onLocaleSelect(locale: LocaleOption) {
    open = false
    if (page.url.host !== locale.host) {
      const url = new SvelteURL(window.location.href)
      url.host = locale.host
      url.search = `locale=${locale.code}`
      window.location.href = url.href
    } else {
      setLocale(locale.code)
    }
  }

  function handleOutsideClick(e: MouseEvent) {
    if (open && containerEl && !containerEl.contains(e.target as Node)) {
      open = false
    }
  }

  function handleKeydown(e: KeyboardEvent) {
    if (e.key === 'Escape' && open) {
      open = false
    }
  }
</script>

<svelte:window onclick={handleOutsideClick} onkeydown={handleKeydown} />

<div class="lang-selector" bind:this={containerEl} {id}>
  <button
    class="lang-trigger"
    onclick={() => (open = !open)}
    aria-expanded={open}
    title={m['actions.selectLanguage']()}
  >
    <img
      src={`/flags/${currentLocale}.png`}
      aria-hidden="true"
      alt=""
      class="lang-flag"
    />
    <span>{LOCALES.find((l) => l.code === currentLocale)!.short}</span>
    <span class="lang-chevron" class:open aria-hidden="true">
      <i class="i-ri-arrow-down-s-line block text-lg"></i>
    </span>
  </button>

  {#if open}
    <div class="lang-dropdown" role="listbox" aria-label={m['actions.selectLanguage']()}>
      {#each LOCALES as locale (locale.code)}
        <button
          class="lang-option"
          class:active={locale.code === currentLocale}
          lang={locale.code}
          role="option"
          aria-selected={locale.code === currentLocale}
          onclick={() => onLocaleSelect(locale)}
        >
          <img
            src={`/flags/${locale.code}.png`}
            aria-hidden="true"
            alt=""
            class="lang-flag"
          />
          <span class="lang-label">{locale.long}</span>
        </button>
      {/each}
    </div>
  {/if}
</div>

<style>
  .lang-selector {
    position: relative;
  }

  .lang-trigger {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.375rem 0.625rem;
    border-radius: 0.5rem;
    border: none;
    background: transparent;
    color: var(--text-action-high-blue-france);
    cursor: pointer;
    font-size: 0.875rem;
    font-weight: 500;
    line-height: 1;
  }

  .lang-trigger:hover {
    color: var(--text-action-high-blue-france);
  }

  .lang-flag {
    width: 22px;
    border-radius: 0.2rem;
  }

  .lang-chevron {
    display: flex;
    transition: transform 0.2s;
  }

  .lang-chevron.open {
    transform: rotate(180deg);
  }

  .lang-dropdown {
    position: absolute;
    top: calc(100% + 0.375rem);
    left: 0;
    min-width: max-content;
    background: var(--background-default-grey);
    border: 1px solid var(--border-default-grey);
    border-radius: 0.5rem;
    box-shadow: 0 4px 16px rgb(0 0 0 / 0.1);
    z-index: 100;
    overflow: hidden;
  }

  .lang-option {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    width: 100%;
    padding: 0.5rem 0.75rem;
    border: none;
    background: transparent;
    color: var(--text-default-grey);
    cursor: pointer;
    font-size: 0.875rem;
    transition: background 0.15s;
    white-space: nowrap;
  }

  .lang-option:hover {
    background: var(--background-alt-grey);
  }

  .lang-option.active {
    color: var(--text-action-high-blue-france);
    font-weight: 600;
    cursor: default;
  }

  .lang-option.active:hover {
    background: transparent;
  }
</style>
