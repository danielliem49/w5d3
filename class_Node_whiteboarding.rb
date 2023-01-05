class Node 
        attr_accessor :val, :next1

        def initialize(val, next1 = nil) 
            @val = val
            @next1 = next1
        end

end

    def linked_list_values(head)

        return head.val if head.next1 == nil
        [head.val] + [linked_list_values(head.next1)]

        # result = []
        # while head.next1 != nil
        #     result << head.val
        #     head = head.next1
        # end
        # result << head.val
        # result
    end

# test_00:
a = Node.new("a");
b = Node.new("b");
c = Node.new("c");
d = Node.new("d");

a.next1 = b;
b.next1 = c;
c.next1 = d;

p linked_list_values(a)