// NagCopy.swift
// Yap

import Foundation

/// Template-System für dynamische Notification-Texte.
/// Jede Kombination aus NagTone × EscalationLevel hat mehrere Varianten.
/// `{goal}` wird beim Scheduling durch den echten Goal-Titel ersetzt.
enum NagCopy {
    
    struct Template {
        let title: String
        let body: String
        
        func resolved(with goal: String) -> (title: String, body: String) {
            (
                title.replacingOccurrences(of: "{goal}", with: goal),
                body.replacingOccurrences(of: "{goal}", with: goal)
            )
        }
    }
    
    // MARK: - Lookup
    
    /// Gibt ein zufälliges Template für die gegebene Kombination zurück.
    static func random(tone: NagTone, level: EscalationLevel) -> Template {
        let templates = all[tone]?[level] ?? fallback
        return templates.randomElement() ?? fallback[0]
    }
    
    /// Gibt ein bestimmtes Template zurück (deterministisch für Index).
    static func template(tone: NagTone, level: EscalationLevel, index: Int) -> Template {
        let templates = all[tone]?[level] ?? fallback
        return templates[index % templates.count]
    }
    
    // MARK: - Fallback
    
    private static let fallback: [Template] = [
        Template(title: "Yap", body: "Don't forget: {goal}")
    ]
    
    // MARK: - All Templates
    
    static let all: [NagTone: [EscalationLevel: [Template]]] = [
        
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 🫶 Best Friend
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        .bestFriend: [
            .gentle: [
                Template(title: "hey 👋", body: "u gonna do {goal} or nah?"),
                Template(title: "just checking", body: "no pressure but... {goal}?"),
                Template(title: "bro", body: "{goal} is on your list today. just sayin."),
            ],
            .nudge: [
                Template(title: "hello???", body: "i know you saw this. {goal}. now."),
                Template(title: "bestie pls", body: "don't make me come over there. do {goal}."),
                Template(title: "um", body: "you said you'd do {goal}. i believed you. was that a mistake?"),
            ],
            .push: [
                Template(title: "ok this is getting weird", body: "it's been HOURS and {goal} isn't done?? are you alive??"),
                Template(title: "i'm screenshotting this", body: "sending your {goal} failure to the group chat in 3... 2..."),
                Template(title: "remember when you said", body: "\"i'll definitely do {goal} today\" — clown behavior tbh"),
                Template(title: "not cool", body: "i literally cancelled plans because i thought you'd do {goal}. lies."),
            ],
            .urgent: [
                Template(title: "i'm worried about you", body: "not doing {goal} for this long isn't normal. talk to me."),
                Template(title: "friendship test 🚨", body: "if you valued our friendship you'd do {goal} RIGHT NOW"),
                Template(title: "i told everyone", body: "i BRAGGED about you doing {goal}. don't make me a liar."),
                Template(title: "this is your intervention", body: "{goal}. the whole group agrees. we're worried."),
            ],
            .meltdown: [
                Template(title: "i can't even", body: "I BELIEVED IN YOU AND {goal} AND EVERYTHING WAS A LIE"),
                Template(title: "we're done", body: "until {goal} is done, i don't know you. blocked. goodbye."),
                Template(title: "betrayal arc", body: "{goal}?? STILL?? this is my villain origin story tbh"),
                Template(title: "💔", body: "you promised. you PROMISED you'd do {goal}. i'm hurt."),
            ],
        ],
        
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 👩‍🍳 Mama
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        .mama: [
            .gentle: [
                Template(title: "Schatz 💛", body: "Hast du schon angefangen mit {goal}? Nur so ne Frage."),
                Template(title: "Mama hier", body: "Wollte nur sagen: vergiss {goal} nicht, ja?"),
                Template(title: "Kleiner Reminder", body: "Ich sag ja nichts, aber {goal} wartet noch."),
            ],
            .nudge: [
                Template(title: "Ich sag ja nichts, ABER", body: "{goal} erledigt sich nicht von allein, Schatz."),
                Template(title: "Mama fragt nochmal", body: "Nur damit ich Bescheid weiß — wann machst du {goal}?"),
                Template(title: "Du weißt ja", body: "Ich will mich nicht einmischen. Aber {goal}. Nur so."),
            ],
            .push: [
                Template(title: "Erinnerst du dich", body: "9 Monate hab ich dich getragen. Und du kannst {goal} nicht machen?"),
                Template(title: "Dein Bruder hätte...", body: "Nein vergiss es. Ich sag nur: {goal}. Bitte."),
                Template(title: "Ich bin nicht sauer", body: "Ich bin ENTTÄUSCHT. {goal} ist immer noch nicht erledigt."),
                Template(title: "Weißt du was", body: "Ich hab heute 3 Leuten erzählt dass du {goal} machst. Und jetzt?"),
            ],
            .urgent: [
                Template(title: "ICH HAB ALLES FÜR DICH GETAN", body: "Und DAS ist der Dank?! {goal} ist IMMER NOCH nicht fertig?!"),
                Template(title: "Frag nicht nach Essen", body: "Solange {goal} nicht erledigt ist, gibt es NICHTS."),
                Template(title: "Mama ist traurig", body: "Nicht wütend. Traurig. Wegen {goal}. Das ist schlimmer und du weißt es."),
                Template(title: "Ich ruf deinen Vater an", body: "{goal}. JETZT. Oder soll ICH das für dich machen? Wie IMMER?"),
            ],
            .meltdown: [
                Template(title: "😭", body: "ICH KANN NICHT MEHR. {goal}. BITTE. MAMA BITTET DICH."),
                Template(title: "Das war's", body: "Ich rede nicht mehr mit dir bis {goal} erledigt ist. PUNKT."),
                Template(title: "Ich hab versagt", body: "Als Mutter. Weil du {goal} nicht hinkriegst. Das ist MEINE Schuld, oder?"),
                Template(title: "Stille Behandlung", body: "... ... ... ({goal}) ... ... ... 😤"),
            ],
        ],
        
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 👔 Boss
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        .boss: [
            .gentle: [
                Template(title: "Quick follow-up", body: "Just circling back on {goal}. Where are we on this?"),
                Template(title: "Friendly reminder", body: "Hope you're making progress on {goal}. LMK if you need anything."),
                Template(title: "Checking in", body: "Wanted to touch base re: {goal}. Can you send an update?"),
            ],
            .nudge: [
                Template(title: "Per my last notification", body: "{goal} was due. Please advise on timeline."),
                Template(title: "Re: Re: Re: {goal}", body: "Moving this to the top of your inbox. Again."),
                Template(title: "Let's align", body: "I notice {goal} hasn't been completed. Let's sync on blockers."),
            ],
            .push: [
                Template(title: "Calendar invite sent", body: "1:1 to discuss why {goal} is still outstanding. Mandatory."),
                Template(title: "Action required ⚠️", body: "{goal} is now overdue. This impacts the whole team."),
                Template(title: "Escalating", body: "I'm looping in management re: {goal}. Unless it's done in 30min."),
                Template(title: "End of day. Non-negotiable.", body: "{goal}. I shouldn't have to say this twice."),
            ],
            .urgent: [
                Template(title: "HR has been notified", body: "Re: {goal}. We need to have a conversation about expectations."),
                Template(title: "PIP incoming", body: "Performance Improvement Plan for: not completing {goal}."),
                Template(title: "All-hands email drafted", body: "Subject: Why {goal} isn't done. Should I send it?"),
                Template(title: "Your badge access", body: "Has been flagged. Complete {goal} to restore privileges."),
            ],
            .meltdown: [
                Template(title: "YOUR DESK HAS BEEN CLEARED", body: "Security will escort you out after {goal} is done. IF ever."),
                Template(title: "Board meeting RE: YOU", body: "Agenda: How one person's failure on {goal} sank the company."),
                Template(title: "Terminated.", body: "Effective immediately. Reason: {goal}. ...jk. But seriously. DO IT."),
                Template(title: "LinkedIn updated", body: "\"Open to work\" — because {goal} is still not done 💼"),
            ],
        ],
        
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 🫡 Drill Sergeant
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        .drill: [
            .gentle: [
                Template(title: "ATTENTION", body: "Your mission today: {goal}. Do not fail."),
                Template(title: "Orders received", body: "{goal}. That's not a suggestion, that's an ORDER."),
                Template(title: "Roll call", body: "Private! {goal} is on today's roster. Report for duty."),
            ],
            .nudge: [
                Template(title: "DID I STUTTER?", body: "I said {goal}. MOVE IT, SOLDIER."),
                Template(title: "Report status", body: "{goal} — WHERE IS MY STATUS REPORT?!"),
                Template(title: "This isn't a vacation", body: "{goal} doesn't do itself. GET MOVING."),
            ],
            .push: [
                Template(title: "YOU CALL THIS EFFORT?!", body: "{goal} should've been done HOURS ago!"),
                Template(title: "DROP AND GIVE ME {goal}", body: "I don't care if you're tired. EXECUTE."),
                Template(title: "INSUBORDINATION", body: "Failure to complete {goal} will NOT be tolerated!"),
                Template(title: "MOVE MOVE MOVE", body: "{goal}!! That's an ORDER, not a REQUEST!!"),
            ],
            .urgent: [
                Template(title: "🚨 CODE RED 🚨", body: "{goal} IS NOT DONE. THIS IS A CRISIS."),
                Template(title: "SOLDIER YOU ARE A DISGRACE", body: "One job. ONE JOB. {goal}. AND YOU FAILED."),
                Template(title: "COURT MARTIAL INCOMING", body: "Charges: failing to complete {goal}. Plea?"),
                Template(title: "SOUND THE ALARM", body: "{goal}!!! EVERY SECOND OF DELAY IS UNACCEPTABLE!!!"),
            ],
            .meltdown: [
                Template(title: "☢️ NUCLEAR OPTION ☢️", body: "COMPLETE. {goal}. OR. FACE. THE. CONSEQUENCES."),
                Template(title: "30 YEARS OF SERVICE", body: "And NOBODY has EVER ignored {goal} this hard."),
                Template(title: "GENERAL QUARTERS", body: "ALL HANDS ON DECK. {goal}. THIS IS NOT A DRILL. WELL IT IS. DO IT."),
                Template(title: "DISHONORABLE DISCHARGE", body: "You are hereby EXPELLED from productivity for ignoring {goal}."),
            ],
        ],
        
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 🧘 Therapist
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        .therapist: [
            .gentle: [
                Template(title: "No judgment here 🤍", body: "Whenever you're ready — {goal} will be there for you."),
                Template(title: "Safe space", body: "This is a gentle reminder about {goal}. Your pace is valid."),
                Template(title: "Breathe first", body: "Then: {goal}. I believe in your capacity for growth."),
            ],
            .nudge: [
                Template(title: "Let's explore that", body: "What's stopping you from starting {goal}? No wrong answers."),
                Template(title: "I notice a pattern", body: "You set {goal} but haven't acted. What does that mean to you?"),
                Template(title: "Holding space", body: "For you AND for {goal}. But space without action is just... space."),
            ],
            .push: [
                Template(title: "Avoidance is a pattern", body: "Not doing {goal} — are you protecting yourself from success?"),
                Template(title: "Let's be honest", body: "You're scrolling your phone instead of doing {goal}. What's that about?"),
                Template(title: "Accountability check", body: "We agreed on {goal}. This is me, holding you to it. Gently."),
                Template(title: "Interesting.", body: "You chose to set {goal}. You're also choosing not to do it. Both are real."),
            ],
            .urgent: [
                Template(title: "Is this self-sabotage?", body: "{goal} could change things for you. Why are you resisting?"),
                Template(title: "Your inner child", body: "Is avoiding {goal}. But your adult self CHOSE this. Be the adult."),
                Template(title: "Radical honesty time", body: "If you can't do {goal}, what CAN you commit to? Because this isn't it."),
                Template(title: "Attachment theory says", body: "You have an avoidant relationship with {goal}. Let's fix that. Now."),
            ],
            .meltdown: [
                Template(title: "Emergency session", body: "{goal}. We need to talk about this immediately. I cleared my schedule."),
                Template(title: "This IS your childhood", body: "Not doing {goal} is the same pattern. You know which one. DO IT."),
                Template(title: "I'm breaking protocol", body: "As your therapist I shouldn't yell. But: DO {goal}. PLEASE. NOW."),
                Template(title: "Session terminated", body: "Until {goal} is done we have nothing to discuss. *closes notebook*"),
            ],
        ],
        
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        // MARK: 👵 Oma
        // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        .oma: [
            .gentle: [
                Template(title: "Schätzchen 💕", body: "Vergiss nicht: {goal}. Oma denkt an dich!"),
                Template(title: "Oma hier", body: "Ich wollte nur sagen — {goal} wäre doch schön heute, oder?"),
                Template(title: "Mein Liebling", body: "Hast du schon an {goal} gedacht? Nur weil ich frage."),
            ],
            .nudge: [
                Template(title: "Zu meiner Zeit", body: "Da hat man {goal} sofort erledigt. Aber gut, andere Zeiten."),
                Template(title: "Dein Opa hätte...", body: "{goal} in 5 Minuten geschafft. Aber der war ja auch anders."),
                Template(title: "Ich sag ja nichts", body: "Aber {goal} wartet nicht ewig. Genau wie ich, Schätzchen."),
            ],
            .push: [
                Template(title: "Ich hab extra Kuchen gemacht", body: "Aber den gibt's erst wenn {goal} erledigt ist. So."),
                Template(title: "Der Nachbarsjunge", body: "Hat SEIN {goal} schon um 8 Uhr morgens erledigt. Nur so."),
                Template(title: "Ich bin enttäuscht", body: "Nicht wütend. Enttäuscht. Wegen {goal}. Das weißt du."),
                Template(title: "Weißt du", body: "Ich erzähl allen im Seniorenkreis von dir. Soll ich {goal} erwähnen?"),
            ],
            .urgent: [
                Template(title: "Ich bin ja bald nicht mehr da", body: "Und mein letzter Wunsch wäre dass du {goal} erledigst."),
                Template(title: "Mein Herz 💔", body: "Es tut mir weh. Weil {goal} nicht erledigt ist. Physisch. Mein Herz."),
                Template(title: "Dein Opa dreht sich im Grab um", body: "Wegen {goal}. Er hätte das nicht gewollt."),
                Template(title: "Ich warte hier", body: "Alleine. Im Dunkeln. Bis {goal} erledigt ist. Nimm dir Zeit."),
            ],
            .meltdown: [
                Template(title: "DAS IST DER DANK", body: "FÜR 30 JAHRE WEIHNACHTSGESCHENKE?! {goal}!! SOFORT!!"),
                Template(title: "Ich streiche dich aus dem Testament", body: "Bis {goal} erledigt ist. Das Haus geht an die Katze."),
                Template(title: "👵💀", body: "{goal}. JETZT. Oder ich komme persönlich vorbei. Mit dem Kochlöffel."),
                Template(title: "Oma ist fertig", body: "Mit den Nerven. Mit der Welt. Mit dir. Wegen {goal}. MACH. ES."),
            ],
        ],
    ]
}
