SuperCopier 2 beta 1.9
======================

SuperCopier2 is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

SuperCopier2 is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

Website:
  http://supercopier.sfxteam.org

E-Mail:
  supercopier@sfxteam.org (preferably put the 'SuperCopier' word  in the e-mail
  subject)

Staff:
  GliGli: Main code,
  Yogi: Original NT Copier,
  ZeuS: Graphical components.

Special thanks to:
  TntWare http://www.tntware.com/ (unicode components),
  Tal Sella http://www.virtualplastic.net/scrow/ (icons),
  Mathias Rauen http://www.madshi.net/ (hook library).

Description:
============

SuperCopier replaces windows explorer file copy and adds many features:
    - Transfer resuming
    - Copy speed control
    - No bugs if You copy more than 2GB at once
    - Copy speed computation
    - Better copy progress display
    - A little faster
    - Copy list editable while copyin
    - Error log
    - Copy list saving/loading
    - ...
    
Compatibility: Windows 95/98/Millenium/NT4/2000/XP/2003Server

History:
========

- v2 beta 1:
    Complete rewrite.
    ... So many new things but it's too long to enumerate :)

- v2 beta 1.9:
    - Better handling of transfer resume (overwrite if resume is not possible
      and new option to force resume without file age verification).
    - Pause can now be used during waiting state or during copy list creation.
    - Better handling of temporization on retry after copy errors
    - Added a notification balloon for insufficient disk space windows.
    - Corrected speed issues with networked copies (especially on upload).
    - Fixed bug with handled processes name case.
    - Fixed bug with language files loading.
    - Fixed one bug with files larger than 4GB (one more :).
    - Fixed bug while cancelling the insufficient disk space window.
    - Fixed bug with renaming on file names containing dots.
    - Fixed bug with 'Always overwrite if different' option for file collisions.
    - GUI bug fixes and enhancements:
	- Lowered CPU usage.
        - Fixed blinking problem with themes.
        - Fixed problem with copy window minimize button click.
        - Better handling of copy window buttons focus.
        - Hopefully fixed the problem with systray progress bars for copy
          windows.

About the author:
=================
  I (GliGli) am looking for an analyst programmer job near Lyon (69,France).
  I know particularly well Delphi (SuperCopier was developed in Delphi),
  if You are interrested, e-mail me at f.guilhaume@free.fr .
  
  