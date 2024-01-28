include std;
include algorithm;
include math;
include stack;

pub fn main(args: []&str) -> !u32 {

    if args.len() <= 1 {
        println("usage: {} <NAME>");
        return error.NotEnoughArgs;
    }

    println("Hello {} !", args[1]);
    defer println("Goodbye {} !", args[1]);

    const full_name = "Abdoulaye Dia";
    let first_name: &const str = full_name.split(" ").first();
    const last_name = full_name.split(" ")[1];

    let age: u16 = 20 + 3;
    
    let me: Person = .{ first_name, last_name, age };

    let number: f32 = 0.0;
    for i in 0..=10 {
        number += number.pow(2).sin(3).sqrt(2);
    }

    println("number: {:.2}", number);

    case number * 2.0 {
        3.14 => {
            std::log::info("PI !");
        },
        n when n.ceil().mod(2) == 0 => {
            std::log::error("What the hell is that result: {}", n);
        },
        n => {
            std::log::info("The number is {}", n);
        },
    };

    cond do {
        (socket, sockaddr) = await listener.accept() => {
            // not sure about this, it looks more like a select..
        },
        full_name == "eheh" => {
            // do something...
        },
        true => {

        }
    };

    let {apples, peaches} = 
        [{ apples: 23 }, { peaches: 13 }, { apples: 1, peaches: 88 }]
        |> Iterator.accumulate({apples: 0, peaches: 0}, fn {a, p}, acc -> { acc.apples += a.default(0), acc.peaches += p if p else 0})
        |> Iterator.filter(std::utils::Even);
}
