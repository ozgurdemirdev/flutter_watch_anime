window.videoController = {
    init: function () {
        return `
      const videoFrame = document.querySelector('#plyrFrame');
      if (videoFrame) {
        videoFrame.onload = () => {
          const player = document.querySelector('media-player');
          if (player) {
            player.play().then(() => {
              player.pause();
            }).catch(err => console.log('Init error:', err));
          }
        }
      }
    `;
    },

    play: function () {
        return `
      const player = document.querySelector('media-player');
      if (player) player.play();
    `;
    },

    pause: function () {
        return `
      const player = document.querySelector('media-player');
      if (player) player.pause();
    `;
    }
};
