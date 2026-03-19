<script lang="ts">
    import { m } from "$lib/i18n/messages"

  let { 
    value = $bindable(0),
    disabled = false 
  }: {
    value?: number
    disabled?: boolean
  } = $props();

  let hovered = $state(0);
  const stars = [1, 2, 3, 4, 5];

  const getStarState = (star: number) => {
    const activeThreshold = hovered > 0 ? hovered : value;
    const isFilled = star <= activeThreshold;
    
    // Is the user about to downgrade his rating?
    const isReducing = hovered > 0 && hovered < value && star > hovered && star <= value;
    
    return { isFilled, isReducing };
  };
</script>

<fieldset 
  class="star-rating" 
  onmouseleave={() => (hovered = 0)}
  disabled={disabled}
  role="radiogroup"
>
    <legend class="rating-label self-center">{m['vote.stars.title']()}</legend>
    <div class="flex flex-row">
        {#each stars as star (star)}
            {@const isFilled = hovered > 0 ? star <= hovered : star <= value}
            {@const isReducing = hovered > 0 && star > hovered && star <= value}
            <button
                type="button"
                class="star-btn"
                onclick={() => value = star}
                onmouseenter={() => (hovered = star)}
                title={m['vote.stars.' + star]()}
                aria-label={m['vote.stars.' + star]()}
            >
            <i class="star-icon 
            {isFilled || isReducing ? 'i-bi-star-fill' : 'i-bi-star'} 
            {isFilled ? 'is-filled' : ''} 
            {isReducing ? 'is-reducing' : ''}">
            </i>
            </button>
        {/each}
    </div>
</fieldset>

<style>
  .star-rating {
    display: inline-flex;
    align-items: center;
    gap: 0.75rem;
  }

  .rating-label {
    float: left; /* Legacy browsers */
    font-size: 1rem;
    font-weight: 600;
  }

  .star-btn {
    background: none;
    border: none;
    padding: 0;
    margin: 0.1rem;
    cursor: pointer;
    font-size: 1.5rem;
    color: color-mix(in srgb, transparent 50%, var(--cg-yellow));
    transition: transform 0.2s cubic-bezier(0.175, 0.885, 0.32, 1.275);
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .star-icon {
    display: inline-block;
    font-size: 1.5rem;
    width: 1em;
    height: 1em;
    color: color-mix(in srgb, transparent 70%, var(--cg-yellow));
    transition: color 0.2s ease, transform 0.2s ease, opacity 0.2s ease;
  }

  .star-icon.is-filled {
    color: var(--cg-yellow);
  }

  .star-icon.is-reducing {
    opacity: 0.3;
    filter: grayscale(0.5);
  }
  
  .star-btn:hover {
    background: none;

    &:not(:disabled) {
        transform: translateY(-3px);
    }
  }

  .star-btn:active:not(:disabled) {
    transform: translateY(-1px) scale(0.9);
  }

  .star-btn:focus-visible {
    outline-offset: 4px;
    border-radius: 4px;
  }

  .star-btn:disabled {
    cursor: not-allowed;
  }
  
  .star-btn:disabled .star-icon {
    filter: grayscale(1);
    opacity: 0.4;
    color: var(--text-mention-grey, #666);
  }
</style>