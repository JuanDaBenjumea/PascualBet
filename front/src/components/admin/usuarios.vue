<template>
    <div class="usuarios">
        <h1>Gestión de Usuarios</h1>
        <table class="tabla-usuarios">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Nombre</th>
                    <th>Email</th>
                    <th>Rol</th>
                    <th>Acciones</th>
                </tr>
            </thead>

            <tbody>
                <tr v-for="usuario in usuarios" :key="usuario.id">
                    <td>{{ usuario.id }}</td>
                    <td>{{ usuario.nombre }}</td>
                    <td>{{ usuario.email }}</td>
                    <td>{{ usuario.rol }}</td>
                    <td>
                        <button @click="editarUsuario(usuario)">Editar</button>
                        <button @click="eliminarUsuario(usuario.id)">Eliminar</button>
                    </td>
                </tr>
            </tbody>
            
        </table>
        <button @click="crearUsuario">Crear Usuario</button>
    </div>
</template>

<script>
export default {
    data() {
        return {
            usuarios: [], // Aquí se almacenarán los usuarios obtenidos de la base de datos
        };
    },
    methods: {
        async obtenerUsuarios() {
            try {
                // Simulación de una llamada a la API para obtener los usuarios
                const response = await fetch('/api/usuarios');
                this.usuarios = await response.json();
            } catch (error) {
                console.error('Error al obtener los usuarios:', error);
            }
        },
        crearUsuario() {
            // Lógica para crear un nuevo usuario
            console.log('Crear usuario');
        },
        editarUsuario(usuario) {
            // Lógica para editar un usuario existente
            console.log('Editar usuario:', usuario);
        },
        eliminarUsuario(id) {
            // Lógica para eliminar un usuario
            console.log('Eliminar usuario con ID:', id);
        },
    },
    mounted() {
        this.obtenerUsuarios(); // Cargar los usuarios al montar el componente
    },
};
</script>

<style scoped>
.usuarios {
    padding: 20px;
}

.tabla-usuarios {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 20px;
}

.tabla-usuarios th,
.tabla-usuarios td {
    border: 1px solid #ddd;
    padding: 8px;
    text-align: left;
}

.tabla-usuarios th {
    background-color: #f4f4f4;
    font-weight: bold;
}

button {
    margin-right: 5px;
    padding: 5px 10px;
    cursor: pointer;
}
</style>