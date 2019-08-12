#!/usr/bin/env ruby

require 'pg'
require 'yaml'
require 'erb'
require 'securerandom'

secrets = YAML.load_file('secrets.yml')
config = YAML.load_file('config.yml')
rows = Array.new

def run_every(seconds)
    last_tick = Time.now
    loop do
      sleep 0.1
      if Time.now - last_tick >= seconds
        last_tick += seconds
        yield
      end
    end
end

def create_vm(name, cpus, memory, volume_capacity, ip)
    # stolen from here https://github.com/andrewgho/genmac
    r_mac = (1..3).collect { "%02x" % [rand 255] }.join(":")
    mac = "AE:AE:AE:#{r_mac}"
    uuid = SecureRandom.uuid
    vm = ERB.new(File.read("./vm.erb")).result(binding)
    file = file.open("./vm.conf", "w")
    file.puts vm
    file.close
end

begin

    conn = PG.connect :dbname => config['database'], :user => secrets['username'], 
        :password => secrets['password']
    
    puts "Successfully logged on to PostgreSQL database #{conn.db} as PostgreSQL user #{conn.user}!"
    puts "Looking for new rows with state #{config["state"]} every #{config["seek_interval"]} seconds"
    run_every(5) do
        res = conn.exec("SELECT * FROM \"#{config["table"]}\" WHERE status = 'pending'")
        res.each do |row|
            if ! rows.include? row
                rows.push(row)
                puts "Found new pending VM!"
                puts "Name: #{row["name"]}"
                create_vm(row["name"], row["cpus"], row["memory"], row["volume_capacity"], row["ip"])
            end
        end
    end

rescue PG::Error => e

    puts e.message 
    
ensure

    conn.close if conn

rescue Fog::Errors::Error => e
            
    puts e.message

ensure

    libvirt_conn.close if libvirt_conn

end