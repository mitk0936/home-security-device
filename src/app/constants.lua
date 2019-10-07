local pins = { motion = 5, dht = 1, positiveLed = 4, negativeLed = 3, gas = 0 }

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
