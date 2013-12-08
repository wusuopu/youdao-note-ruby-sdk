#!/usr/bin/env ruby
#-*- coding:utf-8 -*-

# Copyright (C) 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; If not, see <http://www.gnu.org/licenses/>.
# 
# 2013 - Long Changjin <admin@longchangjin.cn>

require "uri"
require "net/http"
require "cgi"
require "curb"
require "json"


module YoudaoNote
  class Youdao
    attr_reader :authorize_url, :access_url
    attr_accessor :oauth_token

    def initialize(name="", key="", secret="", redirect="", oauth_token="")
      @consumerName = name
      @consumerKey = key
      @consumerSecret = secret
      @redirect_uri = redirect
      @oauth_token = oauth_token
      @host = "https://note.youdao.com/oauth"

      # 认证url
      @authorize_url = "%s/authorize2?client_id=%s&response_type=code&redirect_uri=%s&state=state" % [
        @host, @consumerKey, @redirect_uri]
      # 获取AccessToken url
      @access_url = "#{@host}/access2?client_id=#{@consumerKey}&client_secret=#{@consumerSecret}&grant_type=authorization_code&redirect_uri=#{@redirect_uri}&code="
    end

    def parse_code uri
      # 传入认证后跳转的url，并解析得到code
      if uri.start_with? @redirect_uri then
        uri = URI.parse(uri).query or ""
      end
      if uri.match('code=') then
        uri = CGI.parse(uri)['code'][0]
      end
      uri
    end

    def access_token code
      # 传入解析得到的code，并请求获取access_token
      if !code then
        return ""
      end

      uri = URI("#{@access_url}#{code}")
      res = Net::HTTP.get_response uri
      if res.code != "200" then
        return ""
      end

      begin
        @oauth_token = JSON::load(res.body)['accessToken']
        return @oauth_token
      rescue Exception => e
        p e
        return ""
      end
    end

    def user_get
      # 查看用户信息
      http_get("https://note.youdao.com/yws/open/user/get.json?oauth_token=#{@oauth_token}")
    end

    def notebook_all
      # 查看用户全部笔记本
      http_post("https://note.youdao.com/yws/open/notebook/all.json?oauth_token=#{@oauth_token}")[1]
    end

    def notebook_list(notebook)
      # 列出笔记本下的笔记
      http_post("https://note.youdao.com/yws/open/notebook/list.json?oauth_token=#{@oauth_token}&notebook=#{notebook}")[1]
    end

    def notebook_create(name)
      # 创建笔记本
      http_post("https://note.youdao.com/yws/open/notebook/create.json?oauth_token=#{@oauth_token}", {"name" => name })[1]
    end

    def notebook_delete(notebook, modify_time=0)
      # 删除笔记本
      http_post("https://note.youdao.com/yws/open/notebook/delete.json?oauth_token=#{@oauth_token}", {"notebook" => notebook, "modify_time" => modify_time})[0] == 200
    end

    def note_create(content, source:"", author:"", title:"", create_time:nil, notebook:"")
      # 创建笔记
      header = {"Authorization" => "OAuth oauth_token=\"#{@oauth_token}\""}
      data = [Curl::PostField.content('content', content)]
      if source != "" then
        data.push Curl::PostField.content('source', source)
      end
      if author != "" then
        data.push Curl::PostField.content('author', author)
      end
      if title != "" then
        data.push Curl::PostField.content('title', title)
      end
      if create_time then
        data.push Curl::PostField.content('create_time', create_time.to_s)
      end
      if notebook != "" then
        data.push Curl::PostField.content('notebook', notebook)
      end
      p data
      puts data
      http_post("https://note.youdao.com/yws/open/note/create.json", data, header, true)[1]
    end

    def note_get(path)
      # 查看笔记
      http_post("https://note.youdao.com/yws/open/note/get.json?oauth_token=#{@oauth_token}", {"path" => path})[1]
    end

    def note_update(path, content, source:"", author:"", title:"", create_time:nil)
      # 修改笔记
      header = {"Authorization" => "OAuth oauth_token=\"#{@oauth_token}\""}
      data = [Curl::PostField.content('path', path), Curl::PostField.content('content', content)]
      if source != "" then
        data.push Curl::PostField.content('source', source)
      end
      if author != "" then
        data.push Curl::PostField.content('author', author)
      end
      if title != "" then
        data.push Curl::PostField.content('title', title)
      end
      if create_time then
        data.push Curl::PostField.content('create_time', create_time.to_s)
      end
      p data
      puts data
      http_post("https://note.youdao.com/yws/open/note/update.json", data, header, true)[0] == 200
    end

    def note_move(path, notebook)
      # 移动笔记
      http_post("https://note.youdao.com/yws/open/note/move.json?oauth_token=#{@oauth_token}", {"path" => path, "notebook" => notebook})[1]
    end

    def note_delete(path)
      # 删除笔记
      http_post("https://note.youdao.com/yws/open/note/delete.json?oauth_token=#{@oauth_token}", {"path" => path})[0] == 200
    end

    def share_publish(path)
      # 分享笔记链接
      http_post("https://note.youdao.com/yws/open/share/publish.json?oauth_token=#{@oauth_token}", {"path" => path})[1]
    end

    def resource_upload(file)
      # 上传附件或图片
      header = {"Authorization" => "OAuth oauth_token=\"#{@oauth_token}\""}
      data = [Curl::PostField.file('file', file)]
      http_post("https://note.youdao.com/yws/open/resource/upload.json?oauth_token=#{@oauth_token}", data, header, true)[1]
    end

    def resource_download(src)
      # 下载附件/图片/图标
      uri = "#{src}?oauth_token=#{@oauth_token}"
      begin
        c = Curl::Easy.new uri
        c.timeout = 60
        c.perform
        c.body_str
      rescue Exception => e
        p e
        ""
      end
    end

    private
    def http_post(uri, data={}, header=nil, form_data=false, verbose=false)
      begin
        c = Curl::Easy.new uri
        c.timeout = 60
        #header['Content-Type'] = "multipart/form-data"
        if header then
          c.headers = header
        end
        c.verbose = verbose
        c.multipart_form_post = true
        if form_data then
          #puts data
          c.http_post(*data)
          #c.setopt Curl::CURLOPT_HTTPPOST, data
          #c.http_post
        else
          c.post_body = URI.encode_www_form(data)
          c.perform
        end
        return c.response_code, JSON.load(c.body_str)
      rescue Exception => e
        p e
        return 0, {}
      end
    end

    def http_get uri
      begin
        c = Curl::Easy.new uri
        c.timeout = 60
        c.perform
        JSON.load c.body_str
      rescue Exception => e
        p e
        {}
      end
    end
  end
end
