local pins = {
  motion = 1,
  dht = 4,
  positiveLed = 2,
  negativeLed = 3,
  gas = 0
};

local topics = {
  connectivity = '/connectivity',
  motion = '/motion',
  temp_hum = '/temp-hum',
  gas = '/gas'
};

local intervals = {
  temp_hum = 60000,
  gas = 15000
};

return {
  pins = pins,
  topics = topics,
  intervals = intervals
};
