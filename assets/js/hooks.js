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

// Auto-scroll hook for chat messages
export const AutoScroll = {
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

// Achievement notification hook
export const AchievementNotifications = {
  mounted() {
    this.handleEvent("achievement_unlocked", (payload) => {
      this.playAchievementSound();
      this.showAchievementNotification(payload.achievement);
    });
  },

  playAchievementSound() {
    // Create and play achievement sound
    const audioContext = new (window.AudioContext || window.webkitAudioContext)();
    
    // Create a pleasant achievement sound using Web Audio API
    const oscillator = audioContext.createOscillator();
    const gainNode = audioContext.createGain();
    
    oscillator.connect(gainNode);
    gainNode.connect(audioContext.destination);
    
    // Achievement sound: ascending notes
    oscillator.frequency.setValueAtTime(523.25, audioContext.currentTime); // C5
    oscillator.frequency.setValueAtTime(659.25, audioContext.currentTime + 0.1); // E5
    oscillator.frequency.setValueAtTime(783.99, audioContext.currentTime + 0.2); // G5
    oscillator.frequency.setValueAtTime(1046.50, audioContext.currentTime + 0.3); // C6
    
    oscillator.type = 'sine';
    
    // Envelope for smooth sound
    gainNode.gain.setValueAtTime(0, audioContext.currentTime);
    gainNode.gain.linearRampToValueAtTime(0.3, audioContext.currentTime + 0.05);
    gainNode.gain.exponentialRampToValueAtTime(0.01, audioContext.currentTime + 0.5);
    
    oscillator.start(audioContext.currentTime);
    oscillator.stop(audioContext.currentTime + 0.5);
  },

  showAchievementNotification(achievement) {
    // Create notification popup
    const notification = document.createElement('div');
    notification.className = 'achievement-notification fixed bottom-4 right-4 bg-gradient-to-r from-yellow-400 to-orange-500 text-white p-4 rounded-lg shadow-lg transform translate-x-full transition-transform duration-300 z-50 max-w-sm';
    
    notification.innerHTML = `
      <div class="flex items-center space-x-3">
        <div class="flex-shrink-0">
          <div class="w-8 h-8 bg-yellow-300 rounded-full flex items-center justify-center">
            <span class="text-yellow-800 font-bold">🏆</span>
          </div>
        </div>
        <div class="flex-1">
          <h4 class="font-bold text-sm">Achievement Unlocked!</h4>
          <p class="text-xs opacity-90">${achievement.name}</p>
          <p class="text-xs opacity-75">${achievement.description}</p>
        </div>
      </div>
    `;
    
    document.body.appendChild(notification);
    
    // Animate in
    setTimeout(() => {
      notification.classList.remove('translate-x-full');
    }, 100);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
      notification.classList.add('translate-x-full');
      setTimeout(() => {
        if (notification.parentNode) {
          notification.parentNode.removeChild(notification);
        }
      }, 300);
    }, 5000);
  }
};
