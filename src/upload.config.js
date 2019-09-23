module.exports = {
  connectionDelay: 200,
  baud: 115200,
  source: {
    libs: [
      '../../nodemcu-esp8266-helpers/file.lua',
      '../../nodemcu-esp8266-helpers/wifi.lua',
      '../../nodemcu-esp8266-helpers/sntp.lua'
    ],
    scripts: './app/*.lua',
    static: './static/**/*.json'
  }
};
