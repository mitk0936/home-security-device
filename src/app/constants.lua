local pins = { motion = 1, dht = 4, positiveLed = 2, negativeLed = 1, gas = 0 }

local topics = {
  connectivity = '/connectivity',
  motion = '/motion',
  temp_hum = '/temp-hum',
  gas = '/gas'
};

return {
  pins = pins,
  topics = topics
};
