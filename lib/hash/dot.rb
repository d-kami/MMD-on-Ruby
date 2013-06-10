class Hash
    def method_missing(name, *args)
        if args.size > 0
            self[name.to_s().sub('=', '').to_sym()] = args[0]
        else
            return self[name.to_sym()]
        end
    end
end