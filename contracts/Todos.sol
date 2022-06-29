// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract SimpleStorage {
    struct Todo {
        bool completed;
        string text;
    }

    Todo[] public todos;

    modifier validIndex(uint index) {
        require(index >= 0 && index < todos.length, "invalid index");
        _;
    }

    function create(string calldata _text) external {
        todos.push(Todo({
        text: _text,
        completed: false
        }));
    }

    function get(uint index) external view validIndex(index) returns (string memory text, bool completed) {
        Todo memory todo = todos[index];
        return (todo.text, todo.completed);
    }

    function updateText(uint index, string calldata _text) external validIndex(index) {
        todos[index].text = _text;
    }

    function toggleCompleted(uint index) external validIndex(index) {
        todos[index].completed = !todos[index].completed;
    }

    function remove(uint index) external validIndex(index) {
        for (uint i = index; i < todos.length - 1; i++) {
            todos[i] = todos[i + 1];
        }
        todos.pop();
    }
}
