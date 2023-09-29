{ lib
, stdenv
, fetchFromGitHub
, cmake
, alsa-lib
, gpsd
, gpsdSupport ? false
, hamlib
, hamlibSupport ? true
, perl
, python3
, espeak
, udev
, extraScripts ? false
}:

stdenv.mkDerivation rec {
  pname = "direwolf";
  version = "1.6";

  src = fetchFromGitHub {
    owner = "wb2osz";
    repo = "direwolf";
    rev = version;
    sha256 = "0xmz64m02knbrpasfij4rrq53ksxna5idxwgabcw4n2b1ig7pyx5";
  };

  nativeBuildInputs = [ cmake ];

  strictDeps = true;

  buildInputs = lib.optionals stdenv.isLinux [ alsa-lib udev ]
    ++ lib.optionals gpsdSupport [ gpsd ]
    ++ lib.optionals hamlibSupport [ hamlib ]
    ++ lib.optionals extraScripts [ python3 perl espeak ];

  preConfigure = lib.optionals (!extraScripts) ''
    echo "" > scripts/CMakeLists.txt
  '';

  postPatch = ''
    substituteInPlace conf/CMakeLists.txt \
      --replace /etc/udev/rules.d/ $out/lib/udev/rules.d/
    substituteInPlace src/symbols.c \
      --replace /usr/share/direwolf/symbols-new.txt $out/share/direwolf/symbols-new.txt \
      --replace /opt/local/share/direwolf/symbols-new.txt $out/share/direwolf/symbols-new.txt
    substituteInPlace src/decode_aprs.c \
      --replace /usr/share/direwolf/tocalls.txt $out/share/direwolf/tocalls.txt \
      --replace /opt/local/share/direwolf/tocalls.txt $out/share/direwolf/tocalls.txt
    substituteInPlace cmake/cpack/direwolf.desktop.in \
      --replace 'Terminal=false' 'Terminal=true' \
      --replace 'Exec=@APPLICATION_DESKTOP_EXEC@' 'Exec=direwolf'
    substituteInPlace src/dwgpsd.c \
      --replace 'GPSD_API_MAJOR_VERSION > 11' 'GPSD_API_MAJOR_VERSION > 14'
  ''
  + lib.optionalString extraScripts ''
    patchShebangs scripts/dwespeak.sh
    substituteInPlace scripts/dwespeak.sh \
      --replace espeak ${espeak}/bin/espeak
  '';

  meta = with lib; {
    description = "A Soundcard Packet TNC, APRS Digipeater, IGate, APRStt gateway";
    homepage = "https://github.com/wb2osz/direwolf/";
    license = licenses.gpl2;
    platforms = platforms.unix;
    maintainers = with maintainers; [ lasandell ];
  };
}
