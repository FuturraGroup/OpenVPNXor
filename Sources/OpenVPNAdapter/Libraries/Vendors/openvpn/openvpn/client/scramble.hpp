//    OpenVPN -- An application to securely tunnel IP networks
//               over a single port, with support for SSL/TLS-based
//               session authentication and key exchange,
//               packet encryption, packet authentication, and
//               packet compression.
//
//    Copyright (C) 2012-2017 OpenVPN Inc.
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU Affero General Public License Version 3
//    as published by the Free Software Foundation.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU Affero General Public License for more details.
//
//    You should have received a copy of the GNU Affero General Public License
//    along with this program in the COPYING file.
//    If not, see <http://www.gnu.org/licenses/>.

#ifndef OPENVPN_CLIENT_SCRAMBLE_H
#define OPENVPN_CLIENT_SCRAMBLE_H

#include <openvpn/buffer/buffer.hpp>

namespace openvpn {
    enum XORMethod {
        NONE,
        XOR_MASK,
        XOR_PTR_POS,
        REVERSE,
        OBFUSCATE
    };

    struct Scramble {
        XORMethod xormethod;
        size_t xormasklen;
        std::string xormask;
    };

    static void scrambleBuffer(Buffer &buffer, Scramble scramble, bool readPacket) {

      switch (scramble.xormethod) {
        case NONE:
          return;

        case XOR_MASK:
          buffer.mask(scramble.xormask, scramble.xormasklen);
          break;

        case XOR_PTR_POS:
          buffer.xorptrpos();
          break;
          
        case REVERSE:
          buffer.reverse();
          break;

        case OBFUSCATE:
          if (readPacket)
          {
            buffer.mask(scramble.xormask, scramble.xormasklen);
            buffer.xorptrpos();
            buffer.reverse();
            buffer.xorptrpos();
          }
          else
          {
            buffer.xorptrpos();
            buffer.reverse();
            buffer.xorptrpos();
            buffer.mask(scramble.xormask, scramble.xormasklen);
          }
          break;
      }
    }
  
    static void scrambleBuffer(const BufferPtr &buffer, Scramble scramble) {
      switch (scramble.xormethod) {
        case NONE:
          break;

        case XOR_MASK:
          buffer->mask(scramble.xormask, scramble.xormasklen);
          break;

        case XOR_PTR_POS:
          buffer->xorptrpos();
          break;

        case REVERSE:
          buffer->reverse();
          break;

        case OBFUSCATE:
          buffer->xorptrpos();
          buffer->reverse();
          buffer->xorptrpos();
          buffer->mask(scramble.xormask, scramble.xormasklen);
          break;
      }
    }
}

#endif //CORE_SCRAMBLE_H
