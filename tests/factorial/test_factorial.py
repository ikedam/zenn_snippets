import factorial


def test_factorial_0() -> None:
    assert factorial.factorial(0) == 1


def test_factorial_1() -> None:
    assert factorial.factorial(1) == 1


def test_factorial_10() -> None:
    assert factorial.factorial(10) == 3628800
