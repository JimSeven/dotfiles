module.exports = {
  defaultBrowser: "Arc",
  options: {
    hideIcon: true,
  },
  handlers: [
    {
      match: ["whereby.com/*", "meet.google.com/*", "*.youtube.com/*", "youtu.be/*", "teams.microsoft.com/*"],
      browser: "Google Chrome"
    }
  ]
}