<script lang="ts">
  import { browser } from '$app/environment'
  import { goto } from '$app/navigation'
  import { page } from '$app/state'
  import ThemeSelector from '$components/ThemeSelector.svelte'
  import Toaster from '$components/Toaster.svelte'
  import { setI18nContext, setVotesContext } from '$lib/global.svelte'
  import { useToast } from '$lib/helpers/useToast.svelte'
  import { setModelsContext } from '$lib/models'
  import { setCohortContext } from '$lib/stores/cohortStore.svelte'
  import { onMount } from 'svelte'
  import { SvelteURLSearchParams } from 'svelte/reactivity'
  import 'uno.css'
  import '../css/app.css'

  if (browser) {
    // FIXME import only needed parts?
    // @ts-expect-error - DSFR module import
    import('@gouvfr/dsfr/dist/dsfr/dsfr.module.min.js')
  }

  let { children, data } = $props()

  onMount(() => {
    // Remove locale param to avoid locale changes override problems
    const params = new SvelteURLSearchParams(page.url.searchParams)
    if (params.get('locale')) {
      params.delete('locale')
      goto(`?${params}` + page.url.hash)
    }
  })

  setVotesContext(data.votes)
  setModelsContext(data.data)
  setI18nContext()
  setCohortContext()

  function handleError(_event: PromiseRejectionEvent) {
    // FIXME display error page on some error? display custom text in toast?
    useToast('Unexpected error', 10000, 'error')
  }
</script>

<svelte:window on:unhandledrejection={handleError} />

<Toaster />

{@render children()}

<div class="theme-selector-global">
  <ThemeSelector />
</div>

<div id="tooltips"></div>

<style>
  .theme-selector-global > :global(button) {
    display: none;
  }
</style>
