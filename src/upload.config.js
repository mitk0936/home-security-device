module.exports = {
  connectionDelay: 200,
  baud: 115200,
  source: {
    libs: [
      './lib/nodemcu-esp8266-helpers/file.lua',
      './lib/nodemcu-esp8266-helpers/wifi.lua',
      './lib/nodemcu-esp8266-helpers/sntp.lua'
    ],
    scripts: './app/*.lua',
    static: './static/**/*.json'
  }
};
