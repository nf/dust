// CroneEngine_Acid
Engine_Acid : CroneEngine {
	var <synth;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
		synth = {
			arg out, hz=220, amp=0.5, gate=0, cutoff=800, hzlag=0.01, amplag=0.02;
			var hz_ = Lag.ar(K2A.ar(hz), hzlag);
			var amp_ = Lag.ar(K2A.ar(amp), amplag);
      var cutoff_ = Lag.ar(K2A.ar(cutoff), amplag);
      var snd = RLPF.ar(Pulse.ar(hz_, 0.5), cutoff_, 0.2);
      var env = EnvGen.kr(Env.perc(0, 0.5), K2A.ar(gate));
			Out.ar(out, (snd * env * amp_).dup);
		}.play(args: [\out, context.out_b], target: context.xg);

		this.addCommand("hz", "f", { arg msg;
			synth.set(\hz, msg[1]);
		});

		this.addCommand("amp", "f", { arg msg;
			synth.set(\amp, msg[1]);
		});

		this.addCommand("gate", "f", { arg msg;
			synth.set(\gate, msg[1]);
		});

		this.addCommand("cutoff", "f", { arg msg;
			synth.set(\cutoff, msg[1]);
		});
	}

	free {
		synth.free;
	}
}
