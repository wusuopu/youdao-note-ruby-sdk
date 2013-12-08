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

require "./youdao.rb"

note = YoudaoNote::Youdao.new("app name",
                              "key",
                              "secret",
                              "redirect_uri",
                              "oauth_token")
puts "先访问此网页进行认证：\n#{note.authorize_url}"
print "请输入认证后得到的code:"
code = gets

code = note.parse_code code.strip
note.access_token(code)
puts note.oauth_token

p note.user_get
p note.notebook_all
p note.notebook_list "/VujiIr1df45"
p note.notebook_create "new_notebook_1"
p note.notebook_delete "/31AF3714A27E44219E69349FDF7D9719"
p note.note_create("<h2>test</h2>content")
p note.note_get "/VujiIr1df45/web1359205641027"
p note.note_update("/ED0C9F3AD7CD4FDD8518BF9EBEC28A2E/405DDA669978431991BB90FBCCEB3844", "<h2>sdf</h2>sdfsdf<br>sdf")
p note.note_move "/ED0C9F3AD7CD4FDD8518BF9EBEC28A2E/EB3394B3FE5D4D34B671460BDC254399", "/VujiIr1df45"
p note.note_delete "/VujiIr1/EB3394B3FE5D4D34B671460BDC254399"
p note.share_publish "/ED0C9F3AD7CD4FDD8518BF9EBEC28A2E/A4F2EC822357463694D2B26AF9CA573F"
p note.resource_upload ".gitignore"
p note.resource_download "https://note.youdao.com/yws/open/resource/download/976/17161A1F294046CF932B2FFD33B78015"
