require 'mqtt'
require 'json'

chipid, ip = ARGV

pins = [
  { number: 1, type: 'switch', mode: :output },
  { number: 2, type: 'dimmer', mode: :output },
  { number: 3, type: 'aircon', mode: :output }
]

def sub(chipid)
  MQTT::Client.connect('localhost') do |c|
    c.subscribe "/node/#{chipid}" 
    c.get do |t, m|
      puts JSON.parse(m)
    end
  end
end

def ping(chipid, ip, pins)
  MQTT::Client.connect('localhost') do |c|
    c.publish "/jarvis", {
      ip: ip,
      chipid: chipid,
      pins: pins
    }.to_json
  end
end

def bg_ping(chipid, ip, pins)
  Thread.new do 
    while true
      ping(chipid, ip, pins)
      sleep(5)
    end
  end
end

def bg_sub(chipid)
  Thread.new do 
    sub(chipid)
  end
end

th_sub = bg_sub(chipid)
th_ping = bg_ping(chipid, ip, pins)

while true
  cmd = STDIN.gets.chomp
  if cmd == 'exit'
    exit(0)
  elsif cmd == 'ping'
    th_ping = bg_ping(chipid, ip, pins)
  elsif cmd == 'noping'
    Thread.kill(th_ping)
  elsif cmd == 'nosub'
    Thread.kill(th_sub)
  elsif cmd == 'sub'
    th_sub = bg_sub(chipid)
  else
    puts "command not found."
  end
end

