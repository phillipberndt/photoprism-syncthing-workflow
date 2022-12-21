# My Photoprism/Syncthing Workflow

This repository contains instructions for how to set up a workflow to manage
smartphone photos. It relies on [Photoprism](https://photoprism.app/) to
manage the photos and on [Syncthing](https://syncthing.net/) to transfer them.
But this is more than just getting your pictures into Photoprism!

## Features
* Transfers your new pictures into Photoprism, no matter where you are
* Maintains a directory structure matching the albums you create in Photoprism
* Replaces the originals on your phone with compressed versions, so you won't
  have to worry about running out of storage space but can still view them
  offline

## Level of Knowledge Required
This won't be a beginners guide. Feel free to extend it via PRs and/or ask
questions via Issues though.

If you're doing this for the first time, create a backup of all your photos
before starting 🙂

## Considerations
### Hardware
I use this with a
[RaspberryPi 4](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/)
with a [random case](https://www.amazon.de/gp/product/B08TR9KMJM) that had good
reviews for adequate passive cooling and a USB SSD. I found this setup to be
adequate, but YMMV and if you read this years later there might be better choices.

Photoprism runs a lot of inference operations that are CPU intensive, and the
scripts from this repository recompress images and videos, so I would not recommend
running this on weaker hardware.

A PC will do, too, but to be fully hands off, whatever you run this on will have to
be turned on when synchronizing, and the most convenient setup does this in the
middle of the night.

### Network Connectivity
Syncthing can work purely locally within your LAN, but then you won't be able to
synchronize your photos while you are travelling. Syncthing furthermore has features
for NAT hole punching and global discovery, which makes setting it up super easy, but
I personally did not want to hand off any control to some cloud.

What I went for is dynamic DNS (I use [ddnss](https://ddnss.de/)) and port forwarding
set up to connect Syncthing and the Photoprism web UI to the outside world. I use NGINX
as a reverse proxy and have Letsencrypt certificates set up for the DNS name.

## How To
### Set up Syncthing
I went for the [official Docker container](https://hub.docker.com/r/syncthing/syncthing)
on my Raspberry PI. Any other method will work just as well.  Create a system
user and group `syncthing` for the data, or adjust the scripts from this repository
to work with another UID.

Once you have it installed, set up synchronization with your phone for the DCIM folder.

On the phone side, for Android, I recommend _Syncthing-Fork_, since it features better
control over when to run Syncthing than the official client. Especially you can chose to
only run while the phone is charging and in a WIFI, which for me corresponds to "at night".

When setting up the phone side and you went for a DDNS solution like I did, specify the peer
as `tcp://your.dns.name:port`.

Recent Android versions support two-way synchronization between the devices.
Earlier require root. Go for that! If you don't, you won't be able to
synchronize pictures back to your phone.

For now, leave it running, it's going to take a while to copy all your pictures
over.


### Set up Photoprism
I again went for
[the Docker solution](https://docs.photoprism.app/getting-started/docker-compose/)
and here I recommend you do the same. It's much more hands off than the manual setup.

Getting Photoprism up and running is straight forward.

If you currently have any pictures that are not on your phone, or outside the
Camera folder on the phone, import them into the Photoprism `originals` folder
now.

Create a system user and group `photoprism` for all of this, or adjust the
scripts from this repository to work with another UID.

### Install Prerequisites
The scripts from this repository require the following programs to be
installed:

* exiftool
* convert (from ImageMagick)
* ffmpeg
* Python 3's `yaml` module

### Setup Workflow Scripts
Edit `workflows/config.sh` to match your directory structure. Then copy all of
the files to some place and set up a cronjob to invoke `workflow.sh` daily as
root.

I recommend to give all of the scripts a read through. I might do things a
little different than you would expect and you might want to adjust that.

That's it.

Have fun.

## Details
So, how does it work?

Step zero is that Syncthing synchronizes the phone's contents with the
corresponding folder on the Raspberry PI. This means that any new pictures will
be downloaded onto the PI, and if any compressed images are absent on the
phone, they will be uploaded.

The workflow then kicks off with calling
`physically_move_albums_to_folders.py`.  This script looks into the sidecar
files of Photoprism to figure out whether there are images physically in the
main camera folder that were moved into an album. Since I usually prefix my
albums with an ISO date (that is, starting with a year like 2022), and also
sometimes create ephemeral albums to share a couple of images with friends, the
script only acts on albums that follow my naming scheme. It moves those
pictures/albums into a folder with the same name as the album within the
originals folder.

Next, it runs `copy_originals.sh`. This script copies any new images from the
Syncthing folder over to Photoprism's originals folder once they are at least
a day old. (This is to avoid copying bad photos that I didn't have time to sort
out yet.)

The workflow then runs `make_small.sh`. This script looks for files in the
originals folder that do not have a corresponding file in a folder storing
compressed files. For any it finds, it compresses images and videos down to
Full HD at mediocre quality, and stores that copy in the compressed folder. To
distinguish compressed and original files, compressed files get a `_s` suffix
before the extension. E.g. `2022.jpg` becomes `2022_s.jpg`. I am probably a bit
overly paranoid here, but this script runs as the `pi` user rather than any of
the former two in case there's any bad bugs in the compression code.

Next, `switch_with_compressed.sh` looks for originals in the Syncthing folder
and replaces them with the compressed version. It double checks that the original
is present before making the switch.

To handle not just sorting of pictures into folders, but also deletion, a script
called `remove_deleted.sh` next deletes compressed versions of pictures for which
no original exists anymore.

The final step is to take a daily backup of the Photoprism database. I have an
additional step to synchronize all data daily to an auxiliary device which I have
not included here.
