module.exports = {
  theme: {
    extend: {
      backgroundImage: {
        'bhabit-dark': 'linear-gradient(to bottom, #000000, #0B0B0F, #101014)',
      },
      fontFamily: {
        heading: ['Prosto One','sans-serif'],
        sans:    ['Raleway','sans-serif'],
        mono:    ['Fragment Mono','monospace'],
      },
      colors: {
        primary: '#FF5E00',
        accent:  '#8B00FF',
        success: '#00CFFF',
        danger:  '#FF3B30',
        neutral: '#E0E0E0',
      },
      spacing: { xs:'8px', sm:'16px', md:'24px', lg:'32px', xl:'48px' },
      borderRadius: { sm:'4px', md:'8px', lg:'16px' },
    },
  },
  plugins: [],
};
