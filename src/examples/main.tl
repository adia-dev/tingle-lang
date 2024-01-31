include std;
include algorithm;
include math;
include stack;

pub struct Person {
    first_name: &const str,
    last_name: &const str,
    age: u16,
}

impl Person {
    pub fn new(first_name: &const str, last_name: &const str, age: u16) -> Self {
        return .{ first_name, last_name, age };
    }
}

pub fn fibonacci(n: u32) -> u32 {
    match n {
        0 => 0,
        1 => 1,
        _ => fibonacci(n - 1) + fibonacci(n - 2),
    }
}

fn add(a: u32, b: u32) -> u32 {
    return a + b;
}

pub fn make_multiplier(factor: u32) -> fn(u32) -> u32 {
    fn multiply(x: u32) -> u32 {
        return x * factor;
    }
    return multiply;
}

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

    let me = Person::new(first_name, last_name, age);

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
        |> Iterator.accumulate({apples: 0, peaches: 0}, fn {a, p}, acc -> { acc.apples += a.default(0), acc.peaches += p if p else 0 })
        |> Iterator.filter(std::utils::Even);

    let times_5 = make_multiplier(5);
    let result = times_5(7);  // Result: 35
    println("Result: {}", result);

    let result_fib = fibonacci(5);
    println("Fibonacci(5): {}", result_fib);

    let result_add = add(5, 7);
    println("Result of add: {}", result_add);

   let pair = (42, "hello");

    match pair {
        (0, _) => println("First element is 0"),
        (_, "world") => println("Second element is 'world'"),
        (x, y) => println("Other pair: ({}, {})", x, y),
    }

    let person = Person { name: "Alice", age };

    match person {
        Person { name: "Alice", age } => println("Found Alice with age: {}", age),
        Person { name, age } => println("Found someone named {} with age: {}", name, age),
    }

    return 0;
}

