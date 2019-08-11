#!/usr/bin/env ruby

require 'pg'
require 'yaml'

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

begin

    conn = PG.connect :dbname => config['database'], :user => secrets['username'], 
        :password => secrets['password']

    libvirt_conn = Fog::Compute.new(
            :provider => "libvirt",
            :libvirt_uri => "qemu:///system?socket=/var/run/libvirt/libvirt-sock"
    )
    
    puts "Successfully logged on to PostgreSQL database #{conn.db} as PostgreSQL user #{conn.user}!"
    puts "Looking for new rows with state #{config["state"]} every #{config["seek_interval"]} seconds"
    run_every(5) do
        res = conn.exec("SELECT * FROM \"#{config["table"]}\" WHERE status = 'pending'")
        res.each do |row|
            if ! rows.include? row
                rows.push(row)
                puts "Found new pending VM!"
                puts "Name: #{row["name"]}"
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