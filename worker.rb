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

def create_vm(id, name, cpus, memory, volume_capacity, ip, config)
    base_path = config["base_path"]
    mac = (1..3).collect { "%02x" % rand(0..255) }.join(":")
    mac = "ae:ae:ae:#{mac}"
    vm = ERB.new(File.read("./vm.erb")).result(binding)
    file = File.open("./#{name}-#{ip}.xml", "w") { |f| f.write(vm) }
    return mac
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
                mac = create_vm(row["id"], row["name"], row["cpus"], row["memory"], row["volume_capacity"], row["ip"], config)
                conn.exec("UPDATE #{config["table"]} SET mac = '#{mac}', status = NULL WHERE id = #{row["id"]}")
                puts "Updated VM #{row["name"]} with MAC address #{mac}"
                system("#{config["deploy_location"]} #{row["name"]}-#{row["ip"].gsub(".", "-")} #{row["disk"]}")
                if $?.exitstatus == 0
                    puts "Deployed VM #{row["name"]}"
                else
                    puts "Failed to deploy VM. Requeuing..."
                    conn.exec("UPDATE #{config["table"]} SET mac = NULL, status = 'pending' WHERE id = #{row["id"]}")
                    rows.delete(row)
                    File.unlink("#{row["name"]}-#{row["ip"].gsub(".", "-")}.xml")
                    puts "Rolled back changes on row ##{row["id"]}"
                end
                
            end
        end
    end

rescue PG::Error => e

    puts e.message 
    
ensure

    conn.close if conn

end