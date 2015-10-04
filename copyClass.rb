#!/usr/bin/env ruby

#This script enables you to copy / rename a Parse class using the Parse rest API.

require 'HTTParty'

def main()
	required_env_var_check()
	config = configure_values()
	results = get_existing_class(config)
	create_class_copy(results, config)
end

def configure_values()
	old_class_name = ENV["EXISTING_CLASS_NAME"]
	new_class_name = ENV["NEW_CLASS_NAME"]
	app_id = ENV["APP_ID"]
	rest_api_key = ENV["REST_API_KEY"]
	default_col = [:objectId, :createdAt, :updatedAt, :ACL]
	parse_base_uri = "https://api.parse.com/1/classes/"
	headers = {"X-Parse-Application-Id" => app_id, "X-Parse-REST-API-Key" => rest_api_key}
	return {app_id: app_id, rest_api_key: rest_api_key, default_col: default_col, parse_base_uri: parse_base_uri, headers: headers, old_class_name: old_class_name, new_class_name: new_class_name}
end

def get_existing_class(config)
	#Get the existing data from the old class
	results = HTTParty.get(config[:parse_base_uri]+config[:old_class_name], :headers => config[:headers]) 
	# Confirm the parse class has at least 1 row
	if (!results["error"].nil?) then
		abort("API usage error: #{results["error"]}. Confirm the environment variables you set are correct.\nYOUR ENVIRONMENT VARIABLES:\nAPP_ID: #{ENV["APP_ID"]}\nREST_API_KEY: #{ENV["REST_API_KEY"]}")
	end
	if (results["results"].count == 0) then
		error_message = "ERROR: You need to have a parse class named \"#{config[:old_class_name]}\" with least one row, in order to copy it.  Alternatively correct the env config for the EXISTING_CLASS_NAME using `$export EXISTING_CLASS_NAME=<existing parse class name>`"
		abort(error_message)
	end
	return results
end

def create_class_copy(results, config)
	# Creating a new class and copy over the data
	results["results"].each do |result|
		body = {}
		result.each do |key, val|
			body[key.to_sym] = val unless config[:default_col].include?(key.to_sym)
		end
		HTTParty.post(config[:parse_base_uri]+config[:new_class_name], :headers => config[:headers], :body => body.to_json)
	end
	puts "SUCCESS: \"#{config[:old_class_name]}\" data copied to your new parse class \"#{config[:new_class_name]}\""
	puts "**NOTE: To copy another parse class adjust the environment variables."
end

def required_env_var_check()
	# Confirming that the environment variables have been set
	if (ENV["APP_ID"].nil? || ENV["REST_API_KEY"].nil? || ENV["EXISTING_CLASS_NAME"].nil? || ENV["NEW_CLASS_NAME"].nil?) then
		puts "- Set your existing parse class name:\n`$export EXISTING_CLASS_NAME=<existing parse class name>`" if ENV["EXISTING_CLASS_NAME"].nil?
		puts "- Set your desired name for new parse class:\n`$export NEW_CLASS_NAME=<desired name for new parse class>`" if ENV["NEW_CLASS_NAME"].nil?
		puts "- Set your parse app_id:\n`$export APP_ID=<your parse app id>`" if ENV["APP_ID"].nil?
		puts "- Set your parse rest_app_id:\n`$export REST_API_KEY=<your parse rest api key>`" if ENV["REST_API_KEY"].nil?
		abort("Environment variables missing, see details above.  Find your parse app's keys and id here: https://www.parse.com/apps/<your app name>/edit#keys") 
	end
end

main()
