// Terminal auto-scroll hook
export const TerminalScroll = {
  mounted() {
    this.scrollToBottom();
  },
  
  updated() {
    this.scrollToBottom();
  },
  
  scrollToBottom() {
    this.el.scrollTop = this.el.scrollHeight;
  }
};
