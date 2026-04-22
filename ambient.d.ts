declare module 'katex/dist/contrib/auto-render' {
    import { KatexOptions } from 'katex';
    /**
     * Renders math symbols in the given element.
     */
    function renderMathInElement(elem: HTMLElement, options?: KatexOptions): void;
    export default renderMathInElement;
}