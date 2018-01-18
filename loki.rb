require 'mqtt'
require 'json'

chipid, ip, type = ARGV

def sub(chipid)
  MQTT::Client.connect('localhost') do |c|
    c.subscribe "/dev/#{chipid}" 
    c.get do |t, m|
      c.publish "/dev/feedback", {
        chipid: chipid,
        msg: JSON.parse(m),
        status: 'success'
      }.to_json
      puts m
    end
  end
end

def reg(chipid, ip, type)
  MQTT::Client.connect('localhost') do |c|
    c.publish "/dev/reg", {
      ip: ip,
      chipid: chipid,
      type: type
    }.to_json
  end
end

def ping(chipid, ip)
  MQTT::Client.connect('localhost') do |c|
    c.publish "/dev/ping", {
      ip: ip,
      chipid: chipid 
    }.to_json
  end
end

def bg_ping(chipid, ip)
  Thread.new do 
    while true
      ping(chipid, ip)
      sleep(5)
    end
  end
end

def bg_sub(chipid)
  Thread.new do 
    sub(chipid)
  end
end

reg(chipid, ip, type)
th_sub = bg_sub(chipid)
th_ping = bg_ping(chipid, ip)

while true
  cmd = STDIN.gets.chomp
  if cmd == 'exit'
    exit(0)
  elsif cmd == 'ping'
    th_ping = bg_ping(chipid, ip)
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

