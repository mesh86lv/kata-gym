fn main() {
    println!("__NAME__: hello");
}

#[cfg(test)]
mod tests {
    #[test]
    fn smoke() {
        assert!(true);
    }
}
