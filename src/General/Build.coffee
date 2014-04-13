Build =
  staticPath: '//s.4cdn.org/image/'
  gifIcon: if window.devicePixelRatio >= 2 then '@2x.gif' else '.gif'
  spoilerRange: {}
  shortFilename: (filename, isReply) ->
    # FILENAME SHORTENING SCIENCE:
    # OPs have a +10 characters threshold.
    # The file extension is not taken into account.
    threshold = if isReply then 30 else 40
    ext = filename.match(/\.?[^\.]*$/)[0]
    if filename.length - ext.length > threshold
      "#{filename[...threshold - 5]}(...).#{ext}"
    else
      filename
  thumbRotate: do ->
    n = 0
    -> n = (n + 1) % 3
  postFromObject: (data, boardID) ->
    o =
      # id
      postID:   data.no
      threadID: data.resto or data.no
      boardID:  boardID
      # info
      name:     data.name
      capcode:  data.capcode
      tripcode: data.trip
      uniqueID: data.id
      email:    if data.email then encodeURI data.email.replace /&quot;/g, '"' else ''
      subject:  data.sub
      flagCode: data.country
      flagName: data.country_name
      date:     data.now
      dateUTC:  data.time
      comment:  data.com
      # thread status
      isSticky: !!data.sticky
      isClosed: !!data.closed
      # file
    if data.ext or data.filedeleted
      o.file =
        name:      data.filename + data.ext
        timestamp: "#{data.tim}#{data.ext}"
        url: if boardID is 'f'
          "//i.4cdn.org/#{boardID}/#{data.filename}#{data.ext}"
        else
          "//i.4cdn.org/#{boardID}/#{data.tim}#{data.ext}"
        height:    data.h
        width:     data.w
        MD5:       data.md5
        size:      data.fsize
        turl:      "//#{Build.thumbRotate()}.t.4cdn.org/#{boardID}/#{data.tim}s.jpg"
        theight:   data.tn_h
        twidth:    data.tn_w
        isSpoiler: !!data.spoiler
        isDeleted: !!data.filedeleted
    Build.post o
  post: (o, isArchived) ->
    ###
    This function contains code from 4chan-JS (https://github.com/4chan/4chan-JS).
    @license: https://github.com/4chan/4chan-JS/blob/master/LICENSE
    ###
    {
      postID, threadID, boardID
      name, capcode, tripcode, uniqueID, email, subject, flagCode, flagName, date, dateUTC
      isSticky, isClosed
      comment
      file
    } = o
    isOP = postID is threadID
    {staticPath, gifIcon} = Build

    tripcode = if tripcode
      " <span class=postertrip>#{tripcode}</span>"
    else
      ''

    if email
      emailStart = '<a href="mailto:' + email + '" class="useremail">'
      emailEnd   = '</a>'
    else
      emailStart = ''
      emailEnd   = ''

    switch capcode
      when 'admin', 'admin_highlight'
        capcodeClass = " capcodeAdmin"
        capcodeStart = " <strong class='capcode hand id_admin'" +
          "title='Highlight posts by the Administrator'>## Admin</strong>"
        capcodeIcon  = " <img src='#{staticPath}adminicon#{gifIcon}' " +
          "title='This user is the 4chan Administrator.' class=identityIcon>"
      when 'mod'
        capcodeClass = " capcodeMod"
        capcodeStart = " <strong class='capcode hand id_mod' " +
          "title='Highlight posts by Moderators'>## Mod</strong>"
        capcodeIcon  = " <img src='#{staticPath}modicon#{gifIcon}' " +
          "title='This user is a 4chan Moderator.' class=identityIcon>"
      when 'developer'
        capcodeClass = " capcodeDeveloper"
        capcodeStart = " <strong class='capcode hand id_developer' " +
          "title='Highlight posts by Developers'>## Developer</strong>"
        capcodeIcon  = " <img src='#{staticPath}developericon#{gifIcon}' " +
          "title='This user is a 4chan Developer.' class=identityIcon>"
      else
        capcodeClass = ''
        capcodeStart = ''
        capcodeIcon  = ''

    userID =
      if !capcode and uniqueID
        " <span class='posteruid id_#{uniqueID}'>(ID: " +
          "<span class=hand title='Highlight posts by this ID'>#{uniqueID}</span>)</span> "
      else
        ''

    flag = unless flagCode
      ''
    else if boardID is 'pol'
      " <img src='#{staticPath}country/troll/#{flagCode.toLowerCase()}.gif' alt=#{flagCode} title='#{flagName}' class=countryFlag>"
    else
      " <span title='#{flagName}' class='flag flag-#{flagCode.toLowerCase()}'></span>"

    if file?.isDeleted
      fileHTML = if isOP
        "<div class=file id=f#{postID}><span class=fileThumb>" +
          "<img src='#{staticPath}filedeleted#{gifIcon}' alt='File deleted.' class=fileDeleted>" +
        "</span></div>"
      else
        "<div class=file id=f#{postID}><span class=fileThumb>" +
          "<img src='#{staticPath}filedeleted-res#{gifIcon}' alt='File deleted.' class=fileDeletedRes>" +
        "</span></div>"
    else if file
      fileSize  = $.bytesToString file.size
      fileThumb = file.turl
      if file.isSpoiler
        fileSize = "Spoiler Image, #{fileSize}"
        unless isArchived
          fileThumb = "#{staticPath}spoiler"
          if spoilerRange = Build.spoilerRange[boardID]
            # Randomize the spoiler image.
            fileThumb += "-#{boardID}" + Math.floor 1 + spoilerRange * Math.random()
          fileThumb += '.png'
          file.twidth = file.theight = 100

      imgSrc = if boardID is 'f'
        ''
      else
        "<a class='fileThumb#{if file.isSpoiler then ' imgspoiler' else ''}' href='#{file.url}' target=_blank>" +
          "<img src='#{fileThumb}' alt='#{fileSize}' data-md5=#{file.MD5} style='height: #{file.theight}px; width: #{file.twidth}px;'>" +
        "</a>"

      # html -> text, translate WebKit's %22s into "s
      a = $.el 'a', innerHTML: file.name
      filename = a.textContent.replace /%22/g, '"'
      # shorten filename, get html
      a.textContent = Build.shortFilename filename
      shortFilename = a.innerHTML
      # get html
      a.textContent = filename
      filename      = a.innerHTML.replace /'/g, '&apos;'

      fileDims = if file.name[-3..] is 'pdf' then 'PDF' else "#{file.width}x#{file.height}"
      fileInfo = "<div class=fileText id=fT#{postID}#{if file.isSpoiler then " title='#{filename}'" else ''}>File: <a href='#{file.url}' target=_blank>#{file.timestamp}</a>" +
        "-(#{fileSize}, #{fileDims}#{
          if file.isSpoiler
            ''
          else
            ", <span#{if filename isnt shortFilename then " title='#{filename}'" else ''}>#{shortFilename}</span>"
        }" + ")</div>"

      fileHTML = "<div class=file id=f#{postID}>#{fileInfo}#{imgSrc}</div>"
    else
      fileHTML = ''

    sticky = if isSticky
      " <img src=#{staticPath}sticky#{gifIcon} alt=Sticky title=Sticky class=stickyIcon>"
    else
      ''
    closed = if isClosed
      " <img src=#{staticPath}closed#{gifIcon} alt=Closed title=Closed class=closedIcon>"
    else
      ''

    if isOP and g.VIEW is 'index' and Conf['JSON Navigation']
      pageNum   = Math.floor Index.liveThreadIDs.indexOf(postID) / Index.threadsNumPerPage + 1
      pageIcon  = " <span class=page-num title='This thread is on page #{pageNum} in the original index.'>[#{pageNum}]</span>"
    else
      pageIcon = ''

    if isOP and g.VIEW is 'index'
      replyLink = " &nbsp; <span>[<a href='/#{boardID}/thread/#{threadID}' class=replylink>Reply</a>]</span>"
    else
      replyLink = ''

    container = $.el 'div',
      id: "pc#{postID}"
      className: "postContainer #{if isOP then 'op' else 'reply'}Container"
      innerHTML: <%= grunt.file.read('src/General/html/Build/post.html').replace(/>\s+/g, '>').replace(/\s+</g, '<').replace(/\s+/g, ' ').trim() %>

    for quote in $$ '.quotelink', container
      href = quote.getAttribute 'href'
      continue if href[0] is '/' # Cross-board quote, or board link
      quote.href = "/#{boardID}/thread/#{href}" # Fix pathnames

    container

  summary: (boardID, threadID, posts, files) ->
    text = []
    text.push "#{posts} post#{if posts > 1 then 's' else ''}"
    text.push "and #{files} image repl#{if files > 1 then 'ies' else 'y'}" if files
    text.push 'omitted.'
    $.el 'a',
      className: 'summary'
      textContent: text.join ' '
      href: "/#{boardID}/thread/#{threadID}"

  thread: (board, data, full) ->
    Build.spoilerRange[board] = data.custom_spoiler

    if (OP = board.posts[data.no]) and root = OP.nodes.root.parentNode
      $.rmAll root
    else
      root = $.el 'div',
        className: 'thread'
        id: "t#{data.no}"

    $.add root, Build[if full then 'fullThread' else 'excerptThread'] board, data, OP
    root

  excerptThread: (board, data, OP) ->
    nodes = [if OP then OP.nodes.root else Build.postFromObject data, board.ID]
    if data.omitted_posts or !Conf['Show Replies'] and data.replies
      [posts, files] = if Conf['Show Replies']
        [data.omitted_posts, data.omitted_images]
      else
        # XXX data.images is not accurate.
        [data.replies, data.omitted_images + data.last_replies.filter((data) -> !!data.ext).length]
      nodes.push Build.summary board.ID, data.no, posts, files
    nodes

  fullThread: (board, data) -> Build.postFromObject data, board.ID
