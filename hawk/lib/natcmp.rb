#======================================================================
#                        HA Web Konsole (Hawk)
# --------------------------------------------------------------------
#            A web-based GUI for managing and monitoring the
#          Pacemaker High-Availability cluster resource manager
#
# Copyright (c) 2009-2015 SUSE LLC, All Rights Reserved.
#
# Author: Tim Serong <tserong@suse.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of version 2 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it would be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# Further, this software is distributed without any warranty that it is
# free of the rightful claim of any third person regarding infringement
# or the like.  Any license provided herein, whether implied or
# otherwise, applies only to this software file.  Patent licenses, if
# any, provided herein do not apply to combinations of this program with
# other software, or any other product whatsoever.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston MA 02111-1307, USA.
#
#======================================================================

# Sourced from http://www.gitorious.org/opensuse/build-service/blobs/master/src/api/lib/natcmp.rb
class String

  # 'Natural order' comparison of strings, e.g.
  #
  #   "my_prog_v1.1.0" < "my_prog_v1.2.0" < "my_prog_v1.10.0"
  #
  # which does not follow alphabetically. A secondary
  # parameter, if set to _true_, makes the comparison
  # case insensitive.
  #
  #   "Hello.10".natcmp("Hello.1")  #=> -1
  #
  #   TODO: Invert case flag?
  #
  # CREDIT: Alan Davies, Martin Pool
  #
  #--
  # Adapted from:
  #
  #   http://sourcefrog.net/projects/natsort/natcmp.rb
  #
  # Based on Martin Pool's "Natural Order String Comparison" originally
  # written in C. (see http://sourcefrog.net/projects/natsort/)
  #
  # This implementation is Copyright (C) 2003 by Alan Davies
  # <cs96and_AT_yahoo_DOT_co_DOT_uk>
  #
  # This software is provided 'as-is', without any express or implied
  # warranty.  In no event will the authors be held liable for any damages
  # arising from the use of this software.
  #
  # Permission is granted to anyone to use this software for any purpose,
  # including commercial applications, and to alter it and redistribute it
  # freely, subject to the following restrictions:
  #
  # 1. The origin of this software must not be misrepresented; you must not
  #    claim that you wrote the original software. If you use this software
  #    in a product, an acknowledgment in the product documentation would be
  #    appreciated but is not required.
  # 2. Altered source versions must be plainly marked as such, and must not be
  #    misrepresented as being the original software.
  # 3. This notice may not be removed or altered from any source distribution.
  #
  #++

  def natcmp(str2, caseInsensitive=false)
    str1 = self.dup
    str2 = str2.dup
    compareExpression = /^(\D*)(\d*)(.*)$/

    if caseInsensitive
      str1.downcase!
      str2.downcase!
    end

    # remove all whitespace
    str1.gsub!(/\s*/, '')
    str2.gsub!(/\s*/, '')

    while (str1.length > 0) or (str2.length > 0) do
      # Extract non-digits, digits and rest of string
      str1 =~ compareExpression
      chars1, num1, str1 = $1.dup, $2.dup, $3.dup
      str2 =~ compareExpression
      chars2, num2, str2 = $1.dup, $2.dup, $3.dup
      # Compare the non-digits
      case (chars1 <=> chars2)
        when 0 # Non-digits are the same, compare the digits...
          # If either number begins with a zero, then compare alphabetically,
          # otherwise compare numerically
          if (num1[0] != 48) and (num2[0] != 48)
            num1, num2 = num1.to_i, num2.to_i
          end
          case (num1 <=> num2)
            when -1 then return -1
            when 1 then return 1
          end
        when -1 then return -1
        when 1 then return 1
      end # case
    end # while

    # strings are naturally equal.
    return 0
  end

end
