# -*- coding: utf-8 -*-
require 'open-uri'
require 'active_support/core_ext'
require 'uri'

class RedminesController < ApplicationController

  $api_key = RedMeister::Application.config.api_key
  $api_secret = RedMeister::Application.config.api_secret

  def inputInfo
    if ((params[:text_field][:r_user_name] != "") && (params[:text_field][:r_password] != "") &&  (params[:text_field][:r_url] != ""))
      session["r_user_name"] = params[:text_field][:r_user_name]
      session["r_password"] = params[:text_field][:r_password]
      session["r_url"] = params[:text_field][:r_url]
    end

    redirect_to root_path
  end


  def getProjects
    if (session["r_user_name"] == nil) || (session["r_password"] == nil) ||  (session["r_url"] == nil)
      redirect_to root_path
    else
      # Acquire Redmine Projects
      url_union = session["r_url"] + "/projects.xml?"
      projects_xml = getXML(url_union)

      array = Array.new
      projects_xml["projects"].each{ |p|
        data = Array.new
        data = [ p["name"].to_s, p["identifier"].to_s ]
        array.push(data)
      }
      @projects = array
      session["projects"] = @projects
    end # if(session["r_user_name]" ~
  end


  def getIssues
    session["project_name"] = params[:project_name]
    project_id = params[:project_id]
    url_union = session["r_url"] + "/projects/" + project_id +  "/issues.xml"
    issues_xml = getXML(url_union)

    array = Array.new
    issues_xml["issues"].each{ |p|
      data = Hash.new
      data["id"] = p["id"].to_i
      data["subject"] = p["subject"].to_s
      if p["parent"]
        data["parent"] = p["parent"]["id"].to_i
      else
        data["parent"] = nil
      end

      array.push(data)
    }
    @issues = array
    session["issues"] = @issues
  end


  def postToMindmeister
    array = session["issues"]

    mindmeister_map = addMap
    publishMap(mindmeister_map["id"])
    changeIdeas(mindmeister_map["id"], session["project_name"])

    array.each{ |array_tmp|
      puts array_tmp
      url = "http://www.mindmeister.com/services/rest?api_key=#{$api_key}&auth_token=#{session["auth_token"]}&map_id=#{mindmeister_map["id"]}&method=mm.ideas.insert&parent_id=#{mindmeister_map["id"]}&response_format=xml&title=#{array_tmp["subject"]}&x_pos=200&y_pos=0"
      str = url.clone
      api_sig = md5Converter(str)
      _url = url + "&api_sig=" + api_sig

      uri = URI.escape(_url)
      getXML(uri)
    }

    redirect_to root_path
  end

end
