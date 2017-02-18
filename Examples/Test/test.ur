open Prelude

structure Speed = Enum.Make(struct
    val label = {Hyper = "Hyper", Ludicrous = "Ludicrous", Plaid = "Plaid"}
end)

structure Ureq = UserRequest.Make(struct
    con handlers = [A = (int, int), B = (int, int)]
    type group = int
    type member = int
    fun cont _ ask =
        {A = fn foo =>
                case foo of
                    ({Response = n, Member = m} :: []) =>
                    debug (Str.plural n "object");
                    ask (make [#B] ({Member = 0, Request = n} :: []))
                  | _ => return (),
         B = fn foo =>
                case foo of
                    ({Response = n, Member = m} :: []) =>
                    debug (Str.plural n "thingy");
                    ask (make [#A] ({Member = 0, Request = n} :: []))
                  | _ => return ()}
end)

val start = Ureq.ask 0 (make [#A] ({Member = 0, Request = 9001} :: []))

fun ureq () : transaction page =
    connection <- Ureq.connect {Group = 0, Member = 0};
    let
        fun render srvq =
            case srvq of
                None => <xml>Nothing to do.</xml>
              | Some srv =>
                cases {A = fn sr => <xml>
                         A {[sr.Request]}:
                         {Ui.submitButton
                              {Value = "Click me!",
                               Onclick = sr.Submit (sr.Request + 5)}}
                       </xml>,
                       B = fn sr => <xml>
                         B {[sr.Request]}:
                         {Ui.submitButton
                              {Value = "Click me!",
                               Onclick = sr.Submit (sr.Request - 3)}}
                       </xml>}
                      srv
    in
        return <xml>
          <body>
            <h1>UserRequest Test</h1>
            {xdyn (Monad.mp render (Ureq.value connection))}
            {Ui.submitButton {Value = "Start listening",
                              Onclick = Ureq.listen connection; rpc start}}
          </body>
        </xml>
    end

structure Mt = MagicTable.Make(struct
    con chan = #Channel
    val label_fields = {X = "X", Y = "Y", Z = "Z"}
end)

fun noneify [a] b (v : a) : option a = if b then Some v else None

fun deleteYz yz = Mt.delete (MagicTable.lookup yz)

fun mt () : transaction page =
    cxn <- Mt.connect (MagicTable.select (MagicTable.lookup {Z = True}));
    x <- source "";
    y <- source 0.0;
    z <- source False;
    return <xml>
      <body>
        {xaction (Mt.listen cxn)}
        <h1>MagicTable Test</h1>
        <ctextbox source={x}/><br/>
        <cnumber source={y}/><br/>
        <ccheckbox source={z}/><br/>
        <button value="insert"
                onclick={fn _ =>
                            xyz <- Monad.exec {X = Monad.mp
                                                       (@readError Speed.read)
                                                       (get x),
                                               Y = Monad.mp round (get y),
                                               Z = get z};
                            rpc (Mt.insert xyz)}/>
        <button value="delete"
                onclick={fn _ =>
                            yz <- Monad.exec {Y = Monad.mp round (get y),
                                              Z = get z};
                            rpc (deleteYz yz)}/>
        <hr/>
        {LinkedList.mapX (fn {X = x} =>
                             <xml>X = {[x]}<br/></xml>)
                         (@Mt.value Subset.intro cxn)}
      </body>
    </xml>

val main : transaction page =
    return <xml>
      <body>
        <form>
          <submit value="Make request" action={ureq}/>
        </form>
        <form>
          <submit value="Magic table time" action={mt}/>
        </form>
      </body>
    </xml>
