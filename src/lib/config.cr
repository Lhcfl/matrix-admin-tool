require "yaml"
require "colorize"

module MatrixAdmin
  class Config
    include YAML::Serializable
    getter site : String
    getter token : String

    CONFIG_FILE_PATH = "./config.yaml"

    def initialize(s, t)
      @site = s
      @token = t
    end

    def save!
      File.open(CONFIG_FILE_PATH, "w") do |file|
        file.print self.to_yaml
      end

      puts "Configuration file saved to #{CONFIG_FILE_PATH}".colorize(:green)
      
      self
    end
    
    def self.read_from_file : Config
      File.open(CONFIG_FILE_PATH) { |f| Config.from_yaml(f) }
    end

    def self.create_from_stdin : Config
      print "What's the matrix domain? "
      site = gets.as(String)
      print "What's your admin token? "
      token = gets.as(String)
      
      Config.new(site, token).save!
    end

  end
end
