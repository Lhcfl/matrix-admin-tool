require "./lib/config"
require "http"
require "json"

module MatrixAdmin
  VERSION = "0.1.0"

  @@config : Config = begin
    Config.read_from_file
  rescue File::NotFoundError
    puts "Config file #{Config::CONFIG_FILE_PATH} not found."
    Config.create_from_stdin
  end

  def self.request
    HTTP::Client.new(@@config.site, tls: true)
  end

  def self.headers
    HTTP::Headers{
      "Authorization" => "Bearer #{@@config.token}"
    }
  end

  class Token
    include JSON::Serializable
    getter token : String
    getter completed : Int32
    getter uses_allowed : Int32
    
    def to_s
      "#{@token}\t (#{@completed} of #{@uses_allowed}) registered\n"
    end
  end

  class RegistrationTokens
    include JSON::Serializable

    getter registration_tokens : Array(Token)

    def to_s
      @registration_tokens.map(&.to_s).join("")
    end
  end

  # def self.token_string(x: Hash)
  #   "#{x["token"]}\t (#{x["completed"]} of #{x["uses_allowed"]}) registered\n"
  # end

  def self.get_tokens(para = "")
    puts "[Sending request]"
    res = request.get(
      "/_synapse/admin/v1/registration_tokens#{para}",
      headers: headers,
    )

    RegistrationTokens.from_json(res.body).to_s
    # tok = res.body.json()["registration_tokens"]
  
    # "--------------------\n" +
    #   tok.map do |x|
    #     "#{x["token"]}\t (#{x["completed"]} of #{x["uses_allowed"]}) registered\n"
    #   end.join("") +
    # "--------------------\n"
  end
  
  def self.new_tokens(uses_allowed = 1)
    puts "[Sending request]"
    res = request.post(
      "/_synapse/admin/v1/registration_tokens/new",
      headers: headers,
      body: { uses_allowed: uses_allowed }.to_json,
    )

    Token.from_json(res.body).to_s
    # x = res.body.json()
  
    # "--------------------\n" +
    # "#{x["token"]}\t (#{x["completed"]} of #{x["uses_allowed"]}) registered\n" +
    # "--------------------\n"
  end
  
  def self.del_token(token = "")
    puts "[Sending request]"
  
    request.delete(
      "/_synapse/admin/v1/registration_tokens/#{token}", headers: headers,
    ).body
  end
  
  def self.get_user(user_id = "")
    puts "[Sending request]"
  
    request.get(
      "/_synapse/admin/v2/users/#{user_id}", headers: headers,
    ).body
  end
  
  def self.reset_password(user_id = "")
    pswd = Random.new.hex
    puts "new password: #{pswd}"
    puts "[Sending request]"
  
    request.put(
      "/_synapse/admin/v2/users/#{user_id}",
      headers: headers,
      body: {
        password: pswd,
        logout_devices: false,
      }.to_json
    ).body
  end

  def self.main
    puts <<-HELP
    Command help:
    
    Tokens:
    - list <valid | invalid | all>?
    - gen <number>?
    - delete <token>
    
    Users:
    - get-user <user-id>
    - reset-password <user-id>
    - exit
    
    HELP
    
    
    while true
      print "> "
      matched = /^([a-zA-Z_\-]+)[\s]*([\S]*)/.match(gets.as(String))
    
      unless matched
        puts "Bad Command"
        next  
      end
    
      raw, cmd, param = matched
      
      begin
        case cmd
        when "list"
          para = if param == "valid"
            "?valid=true"
          elsif param == "invalid"
            "?valid=false"
          else
            ""
          end
          puts get_tokens(para)
        when "gen"
          param = param.to_i
          param ||= 1
          puts new_tokens(param)
        when "delete"
          puts del_token(param)
        when "exit"
          puts "Bye bye"
          exit 0
        when "get-user"
          puts get_user(param)
        when "reset-password"
          puts reset_password(param)
        else
          puts "Bad command"
        end
      rescue e  
        puts e.message  
        puts e
      end
    
    end
  end
end


MatrixAdmin.main
