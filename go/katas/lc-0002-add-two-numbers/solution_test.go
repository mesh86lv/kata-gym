package solution

import "testing"

func TestSolveTodo(t *testing.T) {
	defer func() {
		if r := recover(); r == nil {
			t.Fatal("expected panic 'not implemented'")
		}
	}()
	Solve()
}
