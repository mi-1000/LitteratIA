<script lang="ts">
  import { Button, Checkbox } from '$components/dsfr'
  import { arena, initWelcomeAccepted, setWelcomeAccepted } from '$lib/chatService.svelte'
  import { m } from '$lib/i18n/messages'
  import { propsToAttrs } from '$lib/utils/commons'
  import { onMount, tick } from 'svelte'

  let acceptTos = $state(false)
  let tosError = $state<string>()
  let dialogEl = $state<HTMLDialogElement>()

  const pratices = [
    { label: 'welcome.errors', icon: 'i-ri-checkbox-circle-line' },
    { label: 'welcome.privacy', icon: 'i-ri-pass-expired-line' },
    { label: 'welcome.use', icon: 'i-ri-chat-delete-line' }
  ] as const

  onMount(async () => {
    initWelcomeAccepted()
    acceptTos = !!arena.welcomeAccepted

    // open modal if TOS not accepted
    if (!acceptTos && dialogEl) {
      document.body.style.overflow = 'hidden'
      await tick()
      dialogEl.showModal()
    }
  })

  // Réinitialise l'erreur quand l'utilisateur coche la case
  $effect(() => {
    if (acceptTos) tosError = undefined
  })

  function acceptAndClose() {
    if (!acceptTos) {
      tosError = m['home.intro.tos.error']()
      return
    }

    setWelcomeAccepted(true)
    tosError = undefined

    if (dialogEl) {
      // 1. Fermeture native (libère le "inert" sur le reste de la page)
      dialogEl.close()
      // 2. Rétablissement du scroll
      document.body.style.overflow = ''
      // 3. Redonner le focus au document pour réactiver la navigation Tab
      document.body.focus()
    }
  }

  function onKeydown(e: KeyboardEvent) {
    // Empêcher la fermeture via Escape si les CGU ne sont pas acceptées
    if (!acceptTos && e.key === 'Escape') {
      e.preventDefault()
    }
  }

  function onCheckboxKeydown(e: KeyboardEvent) {
    if (e.key === 'Enter') {
      e.preventDefault()
      acceptTos = !acceptTos
    }
  }
</script>

<svelte:window onkeydown={onKeydown} />

<dialog
  bind:this={dialogEl}
  id="fr-modal-welcome"
  class="fr-modal"
  aria-labelledby="fr-modal-title-modal-welcome"
>
  <div class="fr-container fr-container--fluid fr-container-md">
    <div class="fr-grid-row fr-grid-row--center">
      <div class="fr-col-12 fr-col-md-8 fr-col-lg-9">
        <div class="fr-modal__body rounded-xl p-0! m-0!">
          <div class="fr-modal__content m-0! p-0!" id="welcome-modal-body">
            
            <div class="md:grid grid-cols-2">
              <div class="px-7 pb-7 pt-10">
                <h2 id="fr-modal-title-modal-welcome" class="fr-modal__title mb-0! text-primary!">
                  {m['welcome.title']()}
                </h2>
              </div>
              <div class="bg-light-grey md:block hidden"></div>
            </div>

            <div class="md:grid grid-cols-2">
              <div class="px-7 pb-7 flex flex-col justify-evenly">
                {#each pratices as { label } (label)}
                  <div class="md:last-of-type:mb-0">
                    <p class="mb-0! text-[14px]!">{m[label]()}</p>
                  </div>
                {/each}
              </div>
              <div class="bg-light-grey px-7 pt-7 md:pt-0">
                <p class="mb-2!"><strong>{m['home.intro.tos.help']()}</strong></p>
                <p class="mb-0! text-[14px]!">{m['welcome.tos.desc']()}</p>

                <Checkbox
                  bind:checked={acceptTos}
                  id="tos-modal"
                  label={m['home.intro.tos.accept']({
                    linkProps: propsToAttrs({ href: '/modalites', target: '_blank' })
                  })}
                  error={tosError}
                  class={{ 'mb-0!': !tosError }}
                  onkeydown={onCheckboxKeydown}
                />
              </div>
            </div>

            <div class="md:grid grid-cols-2">
              <div class="md:block hidden"></div>
              <div class="bg-light-grey px-7 py-7 flex justify-end">
                <Button
                  text={m['welcome.go']()}
                  onclick={acceptAndClose}
                  disabled={!acceptTos}
                  class="btn-color"
                />
              </div>
            </div>

          </div>
        </div>
      </div>
    </div>
  </div>
</dialog>

<style>
  /* L'élément <dialog> en mode showModal() utilise le "Top Layer".
     On simplifie le CSS pour laisser le navigateur gérer le centrage.
  */
  dialog.fr-modal {
    border: none;
    padding: 0;
    background: transparent;
    width: 100%;
    height: 100%;
    max-width: none;
    max-height: none;
    display: none; /* Par défaut caché */
    align-items: center;
    justify-content: center;
  }

  dialog.fr-modal[open] {
    display: flex; /* Affiché uniquement si ouvert */
  }

  dialog.fr-modal::backdrop {
    background: rgba(0, 0, 0, 0.45);
  }

  .fr-modal__content {
    background: white;
    width: 100%;
    max-width: 980px;
    margin: 0 1rem;
    animation: modalIn 180ms ease;
    box-shadow: 0 10px 25px rgba(0,0,0,0.2);
  }

  @keyframes modalIn {
    from { opacity: 0; transform: translateY(10px); }
    to { opacity: 1; transform: translateY(0); }
  }

  @media (max-width: 767px) {
    .fr-modal__content {
      margin: 0.5rem;
    }
  }
</style>