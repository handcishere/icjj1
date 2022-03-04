
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Deque "mo:base/Deque";
import List "mo:base/List";
import Nat "mo:base/Nat";
import Option "mo:base/Option";
import TrieMap "mo:base/TrieMap";
import Hash "mo:base/Hash";
import Text "mo:base/Text";

import Logger "mo:ic-logger/Logger";
import TextLogger "../example/TextLogger.mo"

shared actor class h() {
    private stable var entries : [var (Nat, Principal)]       = [var];
    private var loggerMap = TrieMap.fromEntries<Nat, Principal>(entries.vals(), Nat.equal, Hash.hash);
    private var currentMessage = 0;
    private var totalMessage = 0;
    private var currentLogger = 0;
    private cur = TextLogger.TextLogger();
    loggerMap.put(0,Principal.fromActor(cur));
    
    public shared (msg) func append(msgs: [Text]) {
        assert(msgs.size() > 0);
        var i = 0;//循环控制
        var c = 0;//当前looger控制

        var s = 100 - currentMessage;
        if(100 - currentMessage >= msgs.size()){
            s := msgs.size();
        };
        var x : [var Text] = Array.init<Text>(s, "");

        label l loop {
           if(i == msgs.size()){
               if(c>0){
                cur.append(x);
               }
               break l;
            };

           if(c == x.size()){
               cur.append(x);

               loggerMap.put(currentLogger,Principal.fromActor(cur));
               currentLogger:=currentLogger+1;
               cur := TextLogger.TextLogger();
               currentMessage := 0 ;


                s := msgs.size() - i;
               if(100  <= msgs.size() - i){
                  s :=100;
                };
               x := Array.init<Text>(s, "");
           };
           


            x[c] := msgs[i];
            currentMessage := currentMessage + 1;
            totalMessage := totalMessage + 1;


            i := i + 1;
            c := c + 1;
        }
    };

    //[from,to]
    public shared query (msg) func view(from: Nat, to: Nat) : async [Text] {
       var res : [var Text] = Array.init<Text>(to - from + 1 , "");
       var x = from;
       var y = to;

       var i = 0;
        label l loop {
            if(x==y){
                break l;
            };
            var a = x/100;//哪个logger
            var b = x%100;//从哪开始view
            var c = 100 - b;//view多少
            if(y-x < c){
                c:=y-x;
            };

            var p = msg.sender;
            switch(loggerMap.get(a)){
                case (?x){
                    p:=x;
                };
            };
            var t : TextLogger = actor(p);

            var temp=await t.view(b,c);
            putSz(res,temp.messages,i);
            i := i + c;
            x := x + c;
        };
    };
    //b的所有push到 a的z开始
    private func putSz(a:[Text],b:[Text],z:Nat){
        var i = 0;
        label l loop {
            if(i==b.size()){
                break l;
            };
            a[z+i] := b[i];
            i := i + 1;
        };
    };
}
