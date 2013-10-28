const float BEACON_ACTIVATION_RADIUS = 128.0f;
const float BEACON_ICON_HEIGHT = 64.0;

aInfoBeacon @infoBeaconHead;

int endlPos(String @str, const uint start) {
	if(start >= str.len()) {
		// die
	}

	int pos = locateAfter(str, "\r\n", start);

	if(pos != -1) {
		return pos;
	}

	pos = locateAfter(str, "\n", start);

	if(pos != -1) {
		return pos;
	}

	return str.len();
}

String @uptoEndl(String @str, const int start) {
	return @str.substr(start, endlPos(str, start) - start);
}

int afterEndl(String @str, const uint start) {
	if(start >= str.len()) {
		// die
	}

	int pos = locateAfter(str, "\r\n", start);

	if(pos != -1) {
		return pos + 2;
	}

	pos = locateAfter(str, "\n", start);

	if(pos != -1) {
		return pos + 1;
	}

	return str.len();
}

int locateAfter(String @haystack, String @needle, const uint start) {
	int maxlen = haystack.len();
	int needlelen = needle.len();

	if(start + needlelen >= maxlen) {
		// die
	}

	for(int pos = start; pos + needlelen <= maxlen; pos++) {
		if(haystack.substr(pos, needlelen) == needle) {
			return pos;
		}
	}

	return -1;
}

class aInfoBeacon { // BACON
	Vec3 origin;

	int soundIdx;
	cInfoSubtitle @subHead;

	aInfoBeacon @next;
	aInfoBeacon @prev;

	void setup(cEntity @ent, String @cfg) {
		this.origin = ent.get_origin();

		String @path = "tutorial/scripts/" + cfg + ".txt"; // TODO: .cfg?

		if(!G_FileExists(path)) {
			// die
			G_Print(path + " does not exist\n");
		}

		int pos = 0;

		String @contents = @G_LoadFile(path);

		int maxpos = contents.len();

		if(maxpos == 0) {
			// die
		}

		String @soundPath = @uptoEndl(contents, pos);
		this.soundIdx = G_SoundIndex(soundPath);

		pos = afterEndl(contents, pos);

		cInfoSubtitle @lastline;

		while(pos < maxpos) {
			String @line = @uptoEndl(@contents, pos);

			String @timestr, sub;

			int spacepos = line.locate(" ", 0);

			if(spacepos == -1) {
				@timestr = @line;
			} else {
				@timestr = @line.substr(0, spacepos);
				@sub = line.substr(spacepos + 1, line.len() - (spacepos + 1)).trim();
			}

			if(!timestr.isNumerical()) {
				// die
			}

			uint time = timestr.toInt();

			this.addSub(time, @sub);

			pos = afterEndl(@contents, pos);
		}

		@this.next = @infoBeaconHead;
		@this.prev = null;

		if(@this.next != null) {
			@this.next.prev = @this;
		}

		@infoBeaconHead = @this;
	}

	void addSub(const uint time, String @sub) {
		if(@this.subHead == null) {
			@this.subHead = cInfoSubtitle(time, sub);
		} else {
			cInfoSubtitle @subFoot;
			for(@subFoot = @this.subHead; @subFoot.next != null; @subFoot = @subFoot.next);

			@subFoot.next = cInfoSubtitle(time, sub);
		}
	}

	void kill() {
		if(@this.prev != null) {
			@this.prev.next = @this.next;
		}

		if(@this.next != null) {
			@this.next.prev = @this.prev;
		}

		if(@this == @infoBeaconHead) {
			@infoBeaconHead = @this.next;
		}
	}

	void think() {
		if(infoDisplay.showing) {
			return;
		}

		cTrace tr;

		cEntity @target = G_GetEntity(0);
		cEntity @stop = G_GetClient(maxClients - 1).getEnt();

		while(true) {
			@target = @G_FindEntityInRadius(target, stop, this.origin, BEACON_ACTIVATION_RADIUS);
			if(@target == null || @target.client == null) {
				break;
			}

			if(target.client.state() < CS_SPAWNED || target.isGhosting()) {
				continue;
			}

			this.nearby(@target.client);

			break; // if there's more than 1 player in tutorial, you suck
		}
	}

	void nearby(cClient @client) {
	}

	void activate(cClient @client) {
		this.display(@client);
	}

	void display(cClient @client) {
		infoDisplay.stop();
		infoDisplay.loadSubtitles(@this);
		infoDisplay.start(@client);
	}

	void stop() {
	}
}

class cInfoBeacon : aInfoBeacon {
	cEntity @model;

	cInfoBeacon(cEntity @ent, String @cfg) {
		this.setup(@ent, @cfg);

		@this.model = @G_SpawnEntity("info_icon");
		this.model.modelindex = infoModelIndex;
		this.model.svflags &= ~SVF_NOCLIENT;
		this.model.set_origin(origin);
		this.model.linkEntity();
	}

	void nearby(cClient @client) {
		G_CenterPrintMsg(@client.getEnt(), "[NAME]\nPress classaction to listen\n");
	}

	void activate(cClient @client) {
		this.display(@client);

		this.model.effects |= EF_ROTATE_AND_BOB;
	}

	void stop() {
		this.model.effects &= ~EF_ROTATE_AND_BOB;
	}
}

class cInfoCheckpoint : aInfoBeacon {
	cInfoCheckpoint(cEntity @ent, String @cfg) {
		this.setup(@ent, @cfg);
	}

	void activate(cClient @client) {
		this.display(@client);

		this.kill();
	}

	void nearby(cClient @client) {
		this.activate(@client);
	}
}

void infoBeaconThinkAll() {
	for(aInfoBeacon @beacon = @infoBeaconHead; @beacon != null; @beacon = @beacon.next) {
		beacon.think();
	}
}

void activateNearestInfoBeacon(cClient @client) {
	aInfoBeacon @nearest;
	float mindist = BEACON_ACTIVATION_RADIUS;

	Vec3 origin = client.getEnt().get_origin();

	for(aInfoBeacon @beacon = @infoBeaconHead; @beacon != null; @beacon = @beacon.next) {
		float dist = origin.distance(beacon.origin);

		if(dist < mindist) {
			@nearest = @beacon;

			mindist = dist;
		}
	}

	if(@nearest != null) {
		nearest.activate(@client);
	}
}

class cInfoSubtitle {
	uint timestamp;
	String @subtitle;

	cInfoSubtitle @next;

	cInfoSubtitle(const uint time, String @sub) {
		this.timestamp = time;
		@this.subtitle = @sub;
	}
}

class cInfoDisplay {
	cClient @student;

	aInfoBeacon @currBeacon;

	cInfoSubtitle @currSubHead;

	bool showing;
	uint startTime;

	cInfoDisplay() {
		this.showing = false;
	}

	void loadSubtitles(aInfoBeacon @beacon) {
		@this.currBeacon = @beacon;

		@this.currSubHead = @beacon.subHead;

		this.startTime = levelTime;
	}

	void start(cClient @client) {
		@this.student = @client;

		G_GlobalSound(CHAN_VOICE, this.currBeacon.soundIdx);

		this.showing = true;
	}

	void stop() {
		if(this.showing) {
			// stop sound
			G_GlobalSound(CHAN_VOICE, G_SoundIndex(""));
			
			this.currBeacon.stop();

			this.showing = false;
		}
	}

	void think() {
		if(this.showing) {
			uint dx = levelTime - startTime;

			if(dx >= this.currSubHead.next.timestamp) {
				@this.currSubHead = @this.currSubHead.next;
			}

			if(@this.currSubHead.subtitle == null) {
				this.stop();
			} else {
				G_CenterPrintMsg(@this.student.getEnt(), this.currSubHead.subtitle);
			}
		}
	}
}

cInfoDisplay infoDisplay;

void misc_info1(cEntity @ent) {
	cInfoBeacon(@ent, "asdf");
}

void misc_info2(cEntity @ent) {
	cInfoCheckpoint(@ent, "asdf");
}
