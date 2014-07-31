sqlite         = require("sqlite3").verbose()
sleep          = require('sleep').sleep
fs             = require("fs")
nodemailer     = require("nodemailer")
chalk          = require("chalk")
changeCase     = require('change-case')
creds          = require('./creds.json')

file           = creds.file
chatname       = creds.chatname
startTimestamp = Math.round(new Date().getTime() / 1000)
destination    = "copyDB.db"

lastTimestamp  = null
refTimeStamp   = null
db             = null
gifs           = []

SELECT  = "SELECT body_xml, timestamp, id FROM Messages WHERE chatname='" + chatname + "'"
SELECT += " AND body_xml LIKE '%.gif%'"
SELECT += " AND timestamp > "

init = ->
    console.log chalk.blue("checking...")

    if fs.existsSync(file)
        copyFileSync file, destination, ->
            db = new sqlite.Database(destination, openDB)
    else 
        console.log chalk.red 'file doesnt exist'
        l00p()


openDB = ->
    #console.log db
    refTimeStamp = if lastTimestamp then lastTimestamp else startTimestamp
    #console.log(refTimeStamp)

    # add timestamp
    selectTimestamp = SELECT + refTimeStamp

    foundIds = 0

    db.all selectTimestamp, (err, rows) ->
        if err 
            console.log chalk.red err
            closeDB()
            return

        if (rows and rows.length > 0) 
            rows.forEach (row) ->
                findGifTag row.id, (tag) ->
                    foundIds++
                    patt = /<a href="(.*.gif)"/g
                    while (match = patt.exec(row.body_xml)) 
                        gifs.push 
                            tag: tag
                            url: match[1]

                    if(foundIds >= rows.length)
                        lastTimestamp = rows[rows.length - 1].timestamp
                        closeDB()
        else 
            console.log chalk.yellow 'nothing...'
            closeDB()

findGifTag = (id, cb) ->
    id = id-1
    db.all "SELECT body_xml FROM Messages WHERE id = #{id}", (err, res) ->
        if res[0].body_xml.indexOf('@gif') > -1
            tag = res[0].body_xml.substr(4, res[0].body_xml.length)
            tag = changeCase.camelCase(tag)
            cb(tag)
        else 
            findGifTag id, cb

copyFileSync = (srcFile, destFile, callback) ->
    BUF_LENGTH = 64*1024
    buff = new Buffer(BUF_LENGTH)
    fdr = fs.openSync(srcFile, 'r')
    fdw = fs.openSync(destFile, 'w')
    bytesRead = 1
    pos = 0
    while bytesRead > 0
        bytesRead = fs.readSync(fdr, buff, 0, BUF_LENGTH, pos)
        fs.writeSync(fdw,buff,0,bytesRead)
        pos += bytesRead
    fs.closeSync(fdr)
    fs.closeSync(fdw)
    callback?()

closeDB = ->
    db.close()
    fs.unlink destination, ->
        if(gifs.length > 0)
            emailTumblr()
        else
            l00p()

l00p = ->
    console.log chalk.green "will loop in 3... \n"
    sleep(3)
    init()

emailTumblr = ->

    attach = []
    tags = ""

    console.log chalk.yellow 'emailling...'

    gifs.forEach (gif) ->
        tags += "#" + gif.tag + "\n"
        slash = gif.url.lastIndexOf('/')
        filename = gif.url.substr(slash, gif.url.length)
        attach.push
            filename: filename
            path: gif.url

    transporter = nodemailer.createTransport
        service: creds.service
        auth: 
            user: creds.user
            pass: creds.pass
    
    mailOptions = 
        from        : creds.user
        to          : creds.to
        attachments : attach
        subject     : tags
        text        : tags

    transporter.sendMail mailOptions, (error, info) ->
        if(error)
            console.log(error)
            emailTumblr()
        else
            console.log chalk.green('Message sent: ' + info.response)
            gifs = []
            l00p()

init()